import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:path_provider/path_provider.dart';

import '../offline/offline_region.dart';
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

  static const _providerId = 'approved-pmtiles-catalog';

  final OfflineRegionCatalog _catalog;
  final OfflineRegionDownloader _downloader;
  final Map<String, Transfer> _activeTransfers = <String, Transfer>{};

  @override
  String get providerId => _providerId;

  @override
  Future<OfflineMapArtifact> prepareOfflineRegion(
    OfflineMapRegion region,
  ) async {
    final entry = await _find(region.id);
    return _downloadAndVerify(entry);
  }

  @override
  Future<void> pauseOfflineRegion(String regionId) async {
    final entry = await _find(regionId);
    final transfer =
        _activeTransfers[regionId] ?? await _downloader.start(entry);
    _activeTransfers[regionId] = transfer;
    await _downloader.pause(transfer);
  }

  @override
  Future<OfflineMapArtifact> resumeOfflineRegion(String regionId) async {
    final entry = await _find(regionId);
    var transfer = _activeTransfers[regionId];
    transfer ??= await _downloader.start(entry);
    _activeTransfers[regionId] = transfer;

    if (transfer.statusNotifier.value == TaskStatus.paused) {
      await _downloader.resume(transfer);
    }
    return _materialize(entry, transfer);
  }

  Future<OfflineMapArtifact> _downloadAndVerify(OfflineRegion entry) async {
    final transfer = await _downloader.start(entry);
    _activeTransfers[entry.id] = transfer;
    return _materialize(entry, transfer);
  }

  Future<OfflineMapArtifact> _materialize(
    OfflineRegion entry,
    Transfer transfer,
  ) async {
    final file = await transfer.file;
    await _downloader.verifyExisting(entry, file);

    await _removeSupersededArtifacts(entry, keep: file);
    _activeTransfers.remove(entry.id);

    return _artifact(entry, file);
  }

  OfflineMapArtifact _artifact(OfflineRegion entry, File file) =>
      OfflineMapArtifact(
        localPath: file.path,
        bytes: file.lengthSync(),
        version: entry.updatedAt.toIso8601String(),
        sha256: entry.sha256,
      );

  @override
  Future<void> deleteOfflineRegion(String regionId) async {
    final transfer = _activeTransfers.remove(regionId);
    if (transfer != null) {
      await _downloader.cancel(transfer);
    }

    final directory = await _offlineDirectory();
    final prefix = '${regionId}-';
    if (!await directory.exists()) return;

    await for (final entity in directory.list()) {
      if (entity is File &&
          entity.uri.pathSegments.last.startsWith(prefix) &&
          entity.path.endsWith('.pmtiles')) {
        await entity.delete();
      }
    }
  }

  Future<OfflineRegion> _find(String id) async {
    if (OfflineRegionCatalog.fromEnvironment() == null) {
      throw StateError(
        'OFFLINE_CATALOG_URL is not configured; an approved licensed catalog is required.',
      );
    }
    final entries = await _catalog.fetch();
    for (final entry in entries) {
      if (entry.id != id) continue;
      if (entry.providerId != _providerId) {
        throw StateError(
          'Offline region "${id}" declares an unsupported provider: ${entry.providerId}.',
        );
      }
      return entry;
    }
    throw StateError(
      'Offline region "${id}" is not present in the approved catalog.',
    );
  }

  Future<Directory> _offlineDirectory() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/offline_regions');
    await directory.create(recursive: true);
    return directory;
  }

  Future<void> _removeSupersededArtifacts(
    OfflineRegion entry, {
    required File keep,
  }) async {
    final directory = await _offlineDirectory();
    final prefix = '${entry.id}-';
    await for (final entity in directory.list()) {
      if (entity is File &&
          entity.path.endsWith('.pmtiles') &&
          entity.path.startsWith(
            directory.path + Platform.pathSeparator + prefix,
          ) &&
          entity.path != keep.path) {
        await entity.delete();
      }
    }
  }
}
