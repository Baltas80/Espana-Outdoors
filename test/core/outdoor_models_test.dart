import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/core/domain/outdoor_models.dart';

void main() {
  test('geo point serializes without framework dependencies', () {
    const point = GeoPoint(latitude: 40.4168, longitude: -3.7038);

    expect(point.toJson(), {
      'latitude': 40.4168,
      'longitude': -3.7038,
    });
  });

  test('offline-critical data are represented by domain models', () {
    const risk = OutdoorRisk(
      level: OutdoorRiskLevel.caution,
      title: 'Precaución',
      reason: 'Condiciones cambiantes',
    );

    const route = RouteSummary(
      id: 'demo',
      name: 'Ruta de prueba',
      distanceMeters: 5000,
      elevationGainMeters: 220,
      estimatedMinutes: 90,
      petFriendly: true,
      risk: risk,
    );

    expect(route.petFriendly, isTrue);
    expect(route.risk?.level, OutdoorRiskLevel.caution);
  });

  test('emergency snapshot preserves minimum operational context', () {
    final snapshot = EmergencySnapshot(
      type: EmergencyType.lost,
      position: const GeoPoint(latitude: 40, longitude: -4),
      accuracyMeters: 12,
      capturedAt: DateTime.utc(2026, 9, 21),
      batteryPercent: 67,
    );

    expect(snapshot.type, EmergencyType.lost);
    expect(snapshot.batteryPercent, 67);
  });
}
