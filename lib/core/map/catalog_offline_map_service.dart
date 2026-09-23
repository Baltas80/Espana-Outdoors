import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:path_provider/path_provider.dart';

import '../offline/offline_region_catalog.dart';
import '../offline/offline_region_downloader.dart';
import 'map_service.dart';

/// Concrete mobile offline provider backed by the application's approved
/// PMTiles catalog. The catalog owns licensing/provenance; the downloader
/// owns resumable transfer and checksum verification.
final class CatalogOfflineMapService implements MapService {
  CatalogOfflineMapService({
    required OfflineRegionCatalog catalog,
    OfflineRegionDownloader downloader = const OfflineRegionDownloader(),
  })  : _catalog = catalog,
        _downloader = downloader;

  final OfflineRegionCatalog _catalog;
  final OfflineRegionDownloader _downloader;
  final Map<String, Transfer> _activeTransfers = <String, Transfer>{};

  @override
  String get providerId => 'approved-pmtiles-catalog';

  @override
  Future<OfflineMapArtifact> prepareOfflineRegion(OfflineMapRegion region) async {
    final entry = await _find(region.id);
    final transfer = await _downloader.start(entry);
    _activeTransfers[region.id] = transfer;
    final file = await transfer.file;
    await _downloader.verifyExisting(entry, file);
    return OfflineMapArtifact(
      localPath: file.path,
      bytes: await file.length(),
      version: entry.updatedAt.toIso8601String(),
      sha256: entry.sha256,
    );
  }

  @override
  Future<void> pauseOfflineRegion(String regionId) async {
    final transfer = _activeTransfers[regionId];
    if (transfer != null) {
      await transfer.pause();
    }
  }

  @override
  Future<OfflineMapArtifact> resumeOfflineRegion(String regionId) =>
      _prepareById(regionId);

  Future<OfflineMapArtifact> _prepareById(String regionId) async {
    final entry = await _find(regionId);
    final transfer = await _downloader.start(entry);
    _activeTransfers[regionId] = transfer;
    final file = await transfer.file;
    await _downloader.verifyExisting(entry, file);
    return OfflineMapArtifact(
      localPath: file.path,
      bytes: await file.length(),
      version: entry.updatedAt.toIso8601String(),
      sha256: entry.sha256,
    );
  }

  @override
  Future<void> deleteOfflineRegion(String regionId) async {
    final transfer = _activeTransfers.remove(regionId);
    if (transfer != null) {
      await transfer.cancel();
    }
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/offline_regions/$regionId.pmtiles');
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<dynamic> _find(String id) async {
    final endpoint = OfflineRegionCatalog.fromEnvironment();
    if (endpoint == null) {
      throw StateError(
        'OFFLINE_CATALOG_URL is not configured; an approved licensed catalog is required.',
      );
    }
    final entries = await _catalog.fetch();
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    throw StateError('Offline region "$id" is not present in the approved catalog.');
  }
}
