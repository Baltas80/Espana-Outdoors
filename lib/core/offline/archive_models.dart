/// Metadata for a guaranteed offline archive.
library;

class OfflineArchiveSource {
  const OfflineArchiveSource({
    required this.regionId,
    required this.providerId,
    required this.uri,
    required this.destinationPath,
    required this.sha256,
    this.expectedBytes,
    this.license,
    this.attribution,
  });

  final String regionId;
  final String providerId;
  final Uri uri;
  final String destinationPath;
  final String sha256;
  final int? expectedBytes;
  final String? license;
  final String? attribution;
}

class OfflineArchiveProgress {
  const OfflineArchiveProgress({required this.completedBytes, this.totalBytes});

  final int completedBytes;
  final int? totalBytes;

  double? get fraction => totalBytes == null || totalBytes == 0
      ? null
      : (completedBytes / totalBytes!).clamp(0, 1);
}

abstract interface class OfflineArchiveDownloader {
  Stream<OfflineArchiveProgress> download(OfflineArchiveSource source);
  Future<bool> verify(OfflineArchiveSource source);
  Future<void> cancel(String regionId);
  Future<void> delete(OfflineArchiveSource source);
}
