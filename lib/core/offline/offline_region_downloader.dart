import 'dart:io';

import 'package:background_downloader/background_downloader.dart';

import 'offline_package_verifier.dart';
import 'offline_region.dart';

class OfflineRegionDownloader {
  const OfflineRegionDownloader();

  Future<Transfer> start(OfflineRegion region) async {
    final task = DownloadTask(
      taskId: 'offline-region-' + region.id,
      url: region.downloadUrl.toString(),
      filename: region.id + '.pmtiles',
      directory: 'offline_regions',
      baseDirectory: BaseDirectory.applicationSupport,
      group: 'offline-regions',
      updates: Updates.statusAndProgress,
      retries: 5,
      allowPause: true,
      transferHints: const {TransferHint.largeFile},
      metaData: region.sha256 == null
          ? region.id
          : region.id + '|sha256=' + region.sha256!,
      displayName: region.name,
    );
    return FileDownloader().transfers.getOrStart(task);
  }

  Future<File> startAndVerify(
    OfflineRegion region, {
    bool requireChecksum = true,
  }) async {
    final transfer = await start(region);
    final file = await transfer.file;
    await const OfflinePackageVerifier().verifyFile(
      file,
      expectedSha256: region.sha256,
      requireChecksum: requireChecksum,
    );
    return file;
  }

  Future<void> verifyExisting(
    OfflineRegion region,
    File file, {
    bool requireChecksum = true,
  }) {
    return const OfflinePackageVerifier().verifyFile(
      file,
      expectedSha256: region.sha256,
      requireChecksum: requireChecksum,
    );
  }

  Future<bool> pause(Transfer transfer) => transfer.pause();
  Future<bool> resume(Transfer transfer) => transfer.resume();
  Future<bool> cancel(Transfer transfer) => transfer.cancel();
}