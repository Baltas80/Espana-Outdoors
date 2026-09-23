import 'package:espana_outdoors/core/map/archive_backed_offline_map_service.dart';
import 'package:espana_outdoors/core/map/map_service.dart';
import 'package:espana_outdoors/core/map/offline_map_download.dart';
import 'package:espana_outdoors/core/offline/archive_downloader.dart';
import 'package:espana_outdoors/core/offline/archive_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDownloader implements OfflineArchiveDownloader {
  int verifyCalls = 0;

  @override
  Stream<OfflineArchiveProgress> download(OfflineArchiveSource source) async* {
    yield const OfflineArchiveProgress(completedBytes: 5, totalBytes: 10);
    yield const OfflineArchiveProgress(completedBytes: 10, totalBytes: 10);
  }

  @override
  Future<bool> verify(OfflineArchiveSource source) async {
    verifyCalls++;
    return true;
  }
}

void main() {
  test('bridges archive progress and marks a region ready after verification',
      () async {
    final downloader = _FakeDownloader();
    final region = const OfflineMapRegion(
      id: 'test',
      name: 'Test',
      bounds: MapBounds(
        west: -3,
        south: 40,
        east: -2,
        north: 41,
      ),
      minZoom: 8,
      maxZoom: 12,
      providerId: 'archive',
      styleVersion: 'v1',
    );
    final source = OfflineArchiveSource(
      regionId: region.id,
      providerId: region.providerId,
      uri: Uri.parse('https://example.invalid/test.mbtiles'),
      destinationPath: '/tmp/test.mbtiles',
      sha256: '00',
      expectedBytes: 10,
    );
    final service = ArchiveBackedOfflineMapService(
      downloader: downloader,
      resolveArchive: (_) async => source,
    );

    final states = <OfflineDownloadState>[];
    final subscription = service.watch(region.id).listen(
      (progress) => states.add(progress.state),
    );

    await service.prepareOfflineRegion(region);
    await subscription.cancel();

    expect(states, contains(OfflineDownloadState.downloading));
    expect(states.last, OfflineDownloadState.ready);
    expect(downloader.verifyCalls, 1);
  });
}
