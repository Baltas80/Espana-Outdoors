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
  test('offline region metadata is parsed and normalized', () {
    final region = OfflineRegion.fromJson(_validRegion());

    expect(region.id, 'madrid-2026-09');
    expect(region.providerId, 'approved-pmtiles-catalog');
    expect(region.downloadUrl.isScheme('https'), isTrue);
    expect(region.licenseUrl.isScheme('https'), isTrue);
    expect(region.attribution, 'Proveedor cartográfico');
    expect(region.sizeBytes, 1024);
    expect(region.updatedAt.isUtc, isTrue);
  });

  test('offline region metadata rejects malformed input', () {
    expect(
      () => OfflineRegion.fromJson({'id': 'broken'}),
      throwsA(isA<FormatException>()),
    );
  });

  test('offline region metadata rejects non-HTTPS downloads', () {
    final invalid = _validRegion()..['downloadUrl'] = 'http://maps.example.com/dev.pmtiles';

    expect(
      () => OfflineRegion.fromJson(invalid),
      throwsA(isA<FormatException>()),
    );
  });

  test('offline region metadata rejects non-HTTPS licence URLs', () {
    final invalid = _validRegion()..['licenseUrl'] = 'http://maps.example.com/license';

    expect(
      () => OfflineRegion.fromJson(invalid),
      throwsA(isA<FormatException>()),
    );
  });

  test('offline region metadata rejects missing attribution', () {
    final invalid = _validRegion()..remove('attribution');

    expect(
      () => OfflineRegion.fromJson(invalid),
      throwsA(isA<FormatException>()),
    );
  });
}
