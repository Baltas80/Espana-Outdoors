import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/core/gpx/gpx_import_service.dart';

void main() {
  group('GpxImportService', () {
    test('imports a GPX track and calculates distance and elevation', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="España Outdoor">
  <trk>
    <name>Ruta de prueba</name>
    <trkseg>
      <trkpt lat="40.0000" lon="-3.0000">
        <ele>100</ele>
        <time>2026-09-21T08:00:00Z</time>
      </trkpt>
      <trkpt lat="40.0010" lon="-3.0000">
        <ele>120</ele>
        <time>2026-09-21T08:10:00Z</time>
      </trkpt>
      <trkpt lat="40.0020" lon="-3.0000">
        <ele>110</ele>
        <time>2026-09-21T08:20:00Z</time>
      </trkpt>
    </trkseg>
  </trk>
</gpx>''';

      final result = const GpxImportService().importString(xml);

      expect(result.name, 'Ruta de prueba');
      expect(result.points, hasLength(3));
      expect(result.distanceMeters, greaterThan(200));
      expect(result.ascentMeters, closeTo(20, 0.001));
      expect(result.descentMeters, closeTo(10, 0.001));
      expect(result.startedAt, DateTime.parse('2026-09-21T08:00:00Z'));
      expect(result.endedAt, DateTime.parse('2026-09-21T08:20:00Z'));
    });

    test('rejects empty track', () {
      expect(
        () => const GpxImportService().importString(
          '<gpx version="1.1" creator="test"><trk><trkseg /></trk></gpx>',
        ),
        throwsFormatException,
      );
    });
  });
}
