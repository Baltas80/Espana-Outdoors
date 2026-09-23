import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/core/offline/offline_map_catalog.dart';

void main() {
  test('accepts a well-formed verified map package', () {
    final package = OfflineMapPackage.fromJson({
      'id': 'murcia-montana',
      'name': 'Montaña de Murcia',
      'providerId': 'licensed-provider',
      'version': '2026.09',
      'uri': 'https://maps.example.test/murcia.mbtiles',
      'sha256': 'a' * 64,
      'bytes': 123456789,
      'license': 'ODbL',
      'attribution': 'Open data attribution',
      'bounds': {
        'west': -2.3,
        'south': 37.5,
        'east': -0.6,
        'north': 38.4,
      },
      'minZoom': 7,
      'maxZoom': 15,
    });

    expect(package, isNotNull);
    expect(package!.region.isValid, isTrue);
    expect(package.bytes, 123456789);
    expect(package.sha256, hasLength(64));
  });

  test('rejects packages with bad integrity metadata', () {
    final package = OfflineMapPackage.fromJson({
      'id': 'broken',
      'name': 'Broken',
      'providerId': 'provider',
      'version': '1',
      'uri': 'https://example.test/map.mbtiles',
      'sha256': 'not-a-sha',
      'bytes': 100,
      'bounds': {
        'west': -3,
        'south': 40,
        'east': -2,
        'north': 41,
      },
      'minZoom': 8,
      'maxZoom': 12,
    });

    expect(package, isNull);
  });
}
