import 'package:espana_outdoors/core/map/map_service.dart';
import 'package:espana_outdoors/core/offline/offline_region_store.dart';
import 'package:flutter_test/flutter_test.dart';

const _region = OfflineMapRegion(
  id: 'spain',
  name: 'Spain',
  bounds: MapBounds(
    west: -9.3,
    south: 35.9,
    east: 4.4,
    north: 43.9,
  ),
  minZoom: 0,
  maxZoom: 14,
  providerId: 'approved-pmtiles-catalog',
  styleVersion: '1',
);

void main() {
  test('ready artifact requires a verified checksum', () {
    const record = OfflineRegionRecord(
      region: _region,
      status: OfflineRegionStatus.ready,
      bytesDownloaded: 100,
      artifactVersion: '2026-10-01',
    );

    expect(record.hasValidArtifact, isFalse);
  });

  test('ready artifact accepts a valid sha-256 checksum', () {
    const record = OfflineRegionRecord(
      region: _region,
      status: OfflineRegionStatus.ready,
      bytesDownloaded: 100,
      localPath: '/data/maps/spain.pmtiles',
      artifactVersion: '2026-10-01',
      sha256: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    );

    expect(record.hasValidArtifact, isTrue);
  });

  test('ready artifact rejects a malformed checksum', () {
    const record = OfflineRegionRecord(
      region: _region,
      status: OfflineRegionStatus.ready,
      bytesDownloaded: 100,
      artifactVersion: '2026-10-01',
      sha256: 'not-a-sha256',
    );

    expect(record.hasValidArtifact, isFalse);
  });
}
