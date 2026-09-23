import '../offline/archive_downloader.dart';
import '../offline/archive_models.dart';
import 'map_service.dart';
import 'offline_map_download.dart';

typedef OfflineArchiveResolver = Future<OfflineArchiveSource> Function(
  OfflineMapRegion region,
);

/// Connects the product-level offline map contract to the reusable archive
/// downloader. The application provides the catalog/resolver; the downloader
/// handles HTTP range resume and SHA-256 verification.
class ArchiveBackedOfflineMapService implements OfflineMapDownloadService {
  ArchiveBackedOfflineMapService({
    required OfflineArchiveDownloader downloader,
    required OfflineArchiveResolver resolveArchive,
  })  : _downloader = downloader,
        _resolveArchive = resolveArchive;

  final OfflineArchiveDownloader _downloader;
  final OfflineArchiveResolver _resolveArchive;
  final Map<String, OfflineDownloadProgress> _progress = {};
  final Map<String, Stream<OfflineDownloadProgress>> _streams = {};
  final Map<String, Stream<OfflineDownloadProgress> Function()> _factories = {};
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
    _setProgress(
      OfflineDownloadProgress(
        region: region,
        state: OfflineDownloadState.downloading,
        completedBytes: 0,
        totalBytes: source.expectedBytes,
      ),
    );

    try {
      await for (final update in _downloader.download(source)) {
        if (_paused.contains(region.id)) {
          return;
        }
        _setProgress(
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
      _setProgress(
        OfflineDownloadProgress(
          region: region,
          state: OfflineDownloadState.ready,
          completedBytes: _progress[region.id]?.completedBytes ??
              source.expectedBytes ??
              0,
          totalBytes: source.expectedBytes,
        ),
      );
    } catch (_) {
      if (_paused.contains(region.id)) return;
      _setProgress(
        OfflineDownloadProgress(
          region: region,
          state: OfflineDownloadState.failed,
          completedBytes: _progress[region.id]?.completedBytes ?? 0,
          totalBytes: source.expectedBytes,
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> pauseOfflineRegion(String regionId) async {
    _paused.add(regionId);
    final previous = _progress[regionId];
    if (previous != null) {
      _setProgress(
        OfflineDownloadProgress(
          region: previous.region,
          state: OfflineDownloadState.paused,
          completedBytes: previous.completedBytes,
          totalBytes: previous.totalBytes,
        ),
      );
    }
  }

  @override
  Future<void> resumeOfflineRegion(String regionId) async {
    _paused.remove(regionId);
    final previous = _progress[regionId];
    if (previous == null) return;
    await prepareOfflineRegion(previous.region);
  }

  @override
  Future<void> deleteOfflineRegion(String regionId) async {
    _paused.remove(regionId);
    _progress.remove(regionId);
  }

  @override
  Stream<OfflineDownloadProgress> watch(String regionId) {
    final stream = _streams[regionId];
    if (stream != null) return stream;
    return const Stream<OfflineDownloadProgress>.empty();
  }

  @override
  Future<void> verifyOfflineRegion(String regionId) async {
    final progress = _progress[regionId];
    if (progress == null) return;
    final source = await _resolveArchive(progress.region);
    final verified = await _downloader.verify(source);
    _setProgress(
      OfflineDownloadProgress(
        region: progress.region,
        state: verified
            ? OfflineDownloadState.ready
            : OfflineDownloadState.failed,
        completedBytes: progress.completedBytes,
        totalBytes: progress.totalBytes,
      ),
    );
    if (!verified) {
      throw StateError('La región offline no es íntegra.');
    }
  }

  @override
  Future<void> updateOfflineRegion(String regionId) =>
      resumeOfflineRegion(regionId);

  void _setProgress(OfflineDownloadProgress next) {
    _progress[next.region.id] = next;
    final factory = _factories[next.region.id];
    if (factory != null) {
      factory().listen((_) {});
    }
  }
}
