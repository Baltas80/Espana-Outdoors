/// Offline map lifecycle contracts. Implementations may use vector tiles, raster tiles or packaged regions.
library;

enum OfflineDownloadState { queued, downloading, paused, ready, failed, deleting }

class OfflineMapProgress {
  const OfflineMapProgress({
    required this.regionId,
    required this.state,
    required this.completedBytes,
    required this.totalBytes,
    this.errorCode,
  });

  final String regionId;
  final OfflineDownloadState state;
  final int completedBytes;
  final int totalBytes;
  final String? errorCode;

  double get fraction => totalBytes <= 0 ? 0 : (completedBytes / totalBytes).clamp(0, 1);
}

abstract interface class OfflineMapService {
  Stream<OfflineMapProgress> download(String regionId);
  Future<void> pause(String regionId);
  Future<void> resume(String regionId);
  Future<void> remove(String regionId);
  Future<bool> isReady(String regionId);
}
