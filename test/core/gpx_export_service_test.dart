import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/core/domain/outdoor_models.dart';
import 'package:espana_outdoors/core/gpx/gpx_export_service.dart';
import 'package:espana_outdoors/core/gpx/gpx_import_service.dart';

void main() {
  test('exports and preserves elevation and timestamps', () {
    final started = DateTime.utc(2026, 9, 23, 8);
    final track = ImportedTrack(
      name: 'Ruta prueba',
      points: const [
        GeoPoint(latitude: 40, longitude: -3),
        GeoPoint(latitude: 40.001, longitude: -3),
      ],
      distanceMeters: 111.0,
      ascentMeters: 20,
      descentMeters: 0,
      startedAt: started,
      endedAt: started.add(const Duration(minutes: 10)),
      elevationsMeters: const [100, 120],
      timestamps: [
        started,
        started.add(const Duration(minutes: 10)),
      ],
    );

    final xml = const GpxExportService().toGpxString(track);
    final roundTrip = const GpxImportService().importString(xml);

    expect(roundTrip.points, hasLength(2));
    expect(roundTrip.elevationsMeters, [100, 120]);
    expect(roundTrip.timestamps, [
      started,
      started.add(const Duration(minutes: 10)),
    ]);
  });
}
