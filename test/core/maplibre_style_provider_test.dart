import 'package:espana_outdoors/core/map/maplibre_style_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production policy accepts HTTPS endpoints', () {
    expect(
      () => MapProductionPolicy.validateEndpoint(
        Uri.parse('https://maps.example.test/basemap/spain.pmtiles'),
        name: 'MAP_PMTILES_URL',
      ),
      returnsNormally,
    );
  });

  test('production policy rejects HTTP endpoints', () {
    expect(
      () => MapProductionPolicy.validateEndpoint(
        Uri.parse('http://maps.example.test/spain.pmtiles'),
        name: 'MAP_PMTILES_URL',
      ),
      throwsStateError,
    );
  });

  test('production policy rejects the public OSM tile server', () {
    expect(
      () => MapProductionPolicy.validateStyleJson(
        '{"sources":{"osm":{"tiles":["https://tile.openstreetmap.org/{z}/{x}/{y}.png"]}}}',
      ),
      throwsStateError,
    );
  });

  test('production policy accepts PMTiles placeholder styles', () {
    expect(
      () => MapProductionPolicy.validateStyleJson(
        '{"sources":{"basemap":{"url":"__PMTILES_URL__"}}}',
      ),
      returnsNormally,
    );
  });
}
