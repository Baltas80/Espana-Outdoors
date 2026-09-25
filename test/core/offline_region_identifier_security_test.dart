import 'package:espana_outdoors/core/offline/offline_region.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _validRegion() => {
      'id': 'madrid-2026-09',
      'name': 'Madrid',
      'description': 'Paquete cartográfico regional',
      'providerId': 'approved-pmtiles-catalog',
      'licenseUrl': 'https://maps.example.com/license',
      'attribution': 'Proveedor cartográfico',
      'downloadUrl': 'https://maps.example.com/madrid.pmtiles',
      'sizeBytes': 1024,
      'updatedAt': '2026-09-23T10:00:00Z',
      'sha256': List.filled(64, 'a').join(),
    };

void main() {
  test('offline region identifiers reject path traversal', () {
    final invalid = _validRegion()..['id'] = '../madrid';

    expect(
      () => OfflineRegion.fromJson(invalid),
      throwsA(isA<FormatException>()),
    );
  });

  test('offline region identifiers reject oversized values', () {
    final invalid = _validRegion()..['id'] = 'a' * 65;

    expect(
      () => OfflineRegion.fromJson(invalid),
      throwsA(isA<FormatException>()),
    );
  });
}
