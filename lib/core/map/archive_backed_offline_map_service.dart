import 'dart:async';

import '../offline/archive_downloader.dart';
import '../offline/archive_models.dart';
import 'map_service.dart';
import 'offline_map_download.dart';

typedef OfflineArchiveResolver = Future<OfflineArchiveSource> Function(
  OfflineMapRegion region,
);

/// Bridges the product-level offline map API to a reusable archive downloader.
class ArchiveBackedOfflineMapService implements OfflineMapDownloadService {
  ArchiveBackedOfflineMapService({
    required OfflineArchiveDownloader downloader,
    required OfflineArchiveResolver resolveArchive,
  })  : _downloader = downloader,
        _resolveArchive = resolveArchive;

  final OfflineArchiveDownloader _downloader;
  final OfflineArchiveResolver _resolveArchive;
  final Map<String, OfflineDownloadProgress> _progress = {};
  final Map<String, StreamController<OfflineDownloadProgress>> _controllers = {};
  final Set<String> _paused = {};

  @override
  String get providerId => 'archive';

  @override
  Future<void> prepareOfflineRegion(OfflineMapRegion region) async {
    if (!region.isValid) {
      throw ArgumentError.value(region, 'region', 'Región offline inválida.');
    }

    _paused.remove(region.id);
    final source = await _resolveArchive(region);
    _emit(
      OfflineDownloadProgress(
        region: region,
        state: OfflineDownloadState.downloading,
        completedBytes: 0,
        totalBytes: source.expectedBytes,
      ),
    );

    try {
      await for (final update in _downloader.download(source)) {
        if (_paused.contains(region.id)) return;
        _emit(
          OfflineDownloadProgress(
            region: region,
            state: OfflineDownloadState.downloading,
            completedBytes: update.completedBytes,
            totalBytes: update.totalBytes,
          ),
        );
      }

      final verified = await _downloader.verify(source);
      if (!verified) {
        throw StateError('El archivo offline no superó la verificación.');
      }

      final latest = _progress[region.id];
      _emit(
        OfflineDownloadProgress(
          region: region,
          state: OfflineDownloadState.ready,
          completedBytes:
              latest?.completedBytes ?? source.expectedBytes ?? 0,
          totalBytes: latest?.totalBytes ?? source.expectedBytes,
        ),
      );
    } catch (_) {
      if (_paused.contains(region.id)) return;
      final latest = _progress[region.id];
      _emit(
        OfflineDownloadProgress(
          region: region,
          state: OfflineDownloadState.failed,
          completedBytes: latest?.completedBytes ?? 0,
          totalBytes: latest?.totalBytes ?? source.expectedBytes,
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> pauseOfflineRegion(String regionId) async {
    _paused.add(regionId);
    final current = _progress[regionId];
    if (current != null) {
      _emit(
        OfflineDownloadProgress(
          region: current.region,
          state: OfflineDownloadState.paused,
          completedBytes: current.completedBytes,
          totalBytes: current.totalBytes,
        ),
      );
    }
  }

  @override
  Future<void> resumeOfflineRegion(String regionId) async {
    _paused.remove(regionId);
    final current = _progress[regionId];
    if (current == null) return;
    await prepareOfflineRegion(current.region);
  }

  @override
  Future<void> deleteOfflineRegion(String regionId) async {
    _paused.remove(regionId);
    _progress.remove(regionId);
    final controller = _controllers.remove(regionId);
    await controller?.close();
  }

  @override
  Stream<OfflineDownloadProgress> watch(String regionId) {
    final controller = _controllers.putIfAbsent(
      regionId,
      () => StreamController<OfflineDownloadProgress>.broadcast(),
    );
    final current = _progress[regionId];
    if (current != null) {
      scheduleMicrotask(() {
        if (!controller.isClosed) controller.add(current);
      });
    }
    return controller.stream;
  }

  @override
  Future<void> verifyOfflineRegion(String regionId) async {
    final current = _progress[regionId];
    if (current == null) return;

    final source = await _resolveArchive(current.region);
    final verified = await _downloader.verify(source);
    _emit(
      OfflineDownloadProgress(
        region: current.region,
        state:
            verified ? OfflineDownloadState.ready : OfflineDownloadState.failed,
        completedBytes: current.completedBytes,
        totalBytes: current.totalBytes,
      ),
    );

    if (!verified) {
      throw StateError('La región offline no es íntegra.');
    }
  }

  @override
  Future<void> updateOfflineRegion(String regionId) =>
      resumeOfflineRegion(regionId);

  void _emit(OfflineDownloadProgress next) {
    _progress[next.region.id] = next;
    final controller = _controllers.putIfAbsent(
      next.region.id,
      () => StreamController<OfflineDownloadProgress>.broadcast(),
    );
    if (!controller.isClosed) controller.add(next);
  }
}
