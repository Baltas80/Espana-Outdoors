/// Offline map download contract. Providers must support resumable, scoped data.
library;

import 'map_service.dart';

enum OfflineDownloadState { queued, downloading, paused, ready, failed, deleted }

class OfflineDownloadProgress {
  const OfflineDownloadProgress({
    required this.region,
    required this.state,
    required this.completedBytes,
    required this.totalBytes,
  });

  final OfflineMapRegion region;
  final OfflineDownloadState state;
  final int completedBytes;
  final int? totalBytes;

  double? get fraction =>
      totalBytes == null || totalBytes == 0
          ? null
          : (completedBytes / totalBytes!).clamp(0, 1);
}

abstract interface class OfflineMapDownloadService extends MapService {
  Stream<OfflineDownloadProgress> watch(String regionId);

  Future<void> verifyOfflineRegion(String regionId);

  Future<void> updateOfflineRegion(String regionId);
}
