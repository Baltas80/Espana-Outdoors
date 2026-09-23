import 'package:espana_outdoors/core/map/map_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validates offline map region geometry and zoom range', () {
    const valid = OfflineMapRegion(
      id: 'pn-sierra-nevada',
      name: 'Sierra Nevada',
      bounds: MapBounds(
        west: -3.5,
        south: 36.9,
        east: -2.9,
        north: 37.2,
      ),
      minZoom: 8,
      maxZoom: 15,
      providerId: 'candidate-vector-provider',
      styleVersion: 'outdoor-v1',
    );

    const invalid = OfflineMapRegion(
      id: 'broken',
      name: 'Broken',
      bounds: MapBounds(west: 10, south: 20, east: 5, north: 25),
      minZoom: 15,
      maxZoom: 8,
      providerId: 'provider',
      styleVersion: 'v1',
    );

    expect(valid.isValid, isTrue);
    expect(invalid.isValid, isFalse);
  });

  test('accepts a cryptographically verifiable offline artifact', () {
    const artifact = OfflineMapArtifact(
      localPath: '/data/maps/sierra.mbtiles',
      bytes: 1024,
      version: '2026-09-23',
      sha256: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    );

    expect(artifact.isValid, isTrue);
  });

  test('rejects an invalid offline artifact', () {
    const artifact = OfflineMapArtifact(
      localPath: '',
      bytes: -1,
      version: '',
      sha256: 'not-a-sha256',
    );

    expect(artifact.isValid, isFalse);
  });
}
