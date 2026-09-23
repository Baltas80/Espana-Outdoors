import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../live_data/live_data_gateway_client.dart';
import '../map/archive_backed_offline_map_service.dart';
import 'archive_downloader.dart';
import 'offline_archive_path.dart';
import 'offline_map_catalog.dart';
import 'offline_region_manager.dart';
import 'offline_region_store.dart';

const _gatewayUrl = String.fromEnvironment('ESPANA_OUTDOOR_API_URL');
final offlineCatalogServiceProvider = Provider<OfflineMapCatalogService?>((ref) {
  final url = _gatewayUrl.trim();
  if (url.isEmpty) return null;

  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return null;

  return GatewayOfflineMapCatalogService(
    HttpLiveDataGateway(
      baseUri: uri,
      bearerToken: null,
    ),
  );
});

final offlineArchiveDownloaderProvider = Provider<OfflineArchiveDownloader>((ref) {
  return PlatformOfflineArchiveDownloader();
});

final offlineMapServiceProvider = Provider<ArchiveBackedOfflineMapService>((ref) {
  final catalog = ref.watch(offlineCatalogServiceProvider);
  if (catalog == null) {
    throw StateError(
      'Configura ESPANA_OUTDOOR_API_URL para habilitar el catálogo offline.',
    );
  }

  return ArchiveBackedOfflineMapService(
    downloader: ref.watch(offlineArchiveDownloaderProvider),
    resolveArchive: (region) async {
      final result = await catalog.packages();
      final package = result.data.where((item) => item.id == region.id).firstOrNull;
      if (package == null) {
        throw StateError('Paquete offline no encontrado: ${region.id}');
      }
      return package.source(await offlineArchivePath(package.id));
    },
  );
});

final offlineRegionManagerProvider = Provider<OfflineRegionManager>((ref) {
  if (kIsWeb) {
    throw UnsupportedError(
      'La gestión de archivos MBTiles offline no está disponible en Web.',
    );
  }
  final manager = OfflineRegionManager(
    store: OfflineRegionStore(),
    mapService: ref.watch(offlineMapServiceProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});