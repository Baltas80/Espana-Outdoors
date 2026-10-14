import 'package:espana_outdoors/core/offline/offline_catalog_parser.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _region(String id) => {
      'id': id,
      'name': id == 'spain' ? 'España' : 'Madrid',
      'description': 'Mapa vectorial de prueba',
      'providerId': 'approved-pmtiles-catalog',
      'licenseUrl': 'https://maps.example.invalid/license',
      'attribution': '© OpenStreetMap contributors',
      'downloadUrl': 'https://maps.example.invalid/$id.pmtiles',
      'sizeBytes': 1024,
      'updatedAt': '2026-10-14T00:00:00Z',
      'sha256': List.filled(64, 'a').join(),
    };

void main() {
  test('selects Spain from a catalog with regional entries first', () {
    final result = parseSpainCatalogEntry([
      _region('madrid-2026-10'),
      _region('spain'),
    ]);

    expect(result.id, 'spain');
    expect(result.name, 'España');
  });

  test('rejects a catalog that only contains regional entries', () {
    expect(
      () => parseSpainCatalogEntry([_region('madrid-2026-10')]),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects a single object for a different region', () {
    expect(
      () => parseSpainCatalogEntry(_region('madrid-2026-10')),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects unsupported catalog JSON shapes', () {
    expect(
      () => parseSpainCatalogEntry('not-a-catalog'),
      throwsA(isA<FormatException>()),
    );
  });
}
