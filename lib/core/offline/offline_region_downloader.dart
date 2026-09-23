import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';

import 'offline_region.dart';

class OfflineRegionDownloader {
  const OfflineRegionDownloader();

  Future<Transfer> start(OfflineRegion region) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Background region downloads are not supported on Web; use the PWA download path.',
      );
    }

    final task = DownloadTask(
      taskId: 'offline-region-${region.id}',
      url: region.downloadUrl.toString(),
      filename: '${region.id}.pmtiles',
      directory: 'offline_regions',
      baseDirectory: BaseDirectory.applicationSupport,
      group: 'offline-regions',
      updates: Updates.statusAndProgress,
      retries: 5,
      allowPause: true,
      transferHints: const {TransferHint.largeFile},
      metaData: region.sha256 == null
          ? region.id
          : '${region.id}|sha256=${region.sha256}',
      displayName: region.name,
    );

    return FileDownloader().transfers.getOrStart(task);
  }

  Future<bool> pause(Transfer transfer) => transfer.pause();
  Future<bool> resume(Transfer transfer) => transfer.resume();
  Future<bool> cancel(Transfer transfer) => transfer.cancel();
}
