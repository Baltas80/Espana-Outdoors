import 'package:espana_outdoors/core/offline/offline_region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline region metadata is parsed and normalized', () {
    final region = OfflineRegion.fromJson({
      'id': 'madrid-2026-09',
      'name': 'Madrid',
      'description': 'Paquete cartográfico regional',
      'downloadUrl': 'https://maps.example.com/madrid.pmtiles',
      'sizeBytes': 1024,
      'updatedAt': '2026-09-23T10:00:00Z',
      'sha256': 'abc123',
    });

    expect(region.id, 'madrid-2026-09');
    expect(region.downloadUrl.isScheme('https'), isTrue);
    expect(region.sizeBytes, 1024);
    expect(region.updatedAt.isUtc, isTrue);
  });

  test('offline region metadata rejects malformed input', () {
    expect(
      () => OfflineRegion.fromJson({'id': 'broken'}),
      throwsA(isA<FormatException>()),
    );
  });
}
