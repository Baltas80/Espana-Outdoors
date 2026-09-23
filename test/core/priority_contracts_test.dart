import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/core/alerts/alert_models.dart';
import 'package:espana_outdoors/core/domain/outdoor_models.dart';
import 'package:espana_outdoors/core/map/map_service.dart';
import 'package:espana_outdoors/core/map/offline_map_download.dart';
import 'package:espana_outdoors/core/routing/elevation_models.dart';
import 'package:espana_outdoors/core/routing/offline_navigation_engine.dart';
import 'package:espana_outdoors/core/routing/routing_models.dart';
import 'package:espana_outdoors/core/safety/sos_models.dart' as sos;

void main() {
  test('routing rejects invalid waypoints', () {
    const request = RoutingRequest(waypoints: [
      RouteWaypoint(latitude: 91, longitude: 0),
      RouteWaypoint(latitude: 40, longitude: -3),
    ]);
    expect(request.isValid, isFalse);
  });

  test('offline map region validates its bounds and zooms', () {
    const region = OfflineMapRegion(
      id: 'spain-test',
      name: 'Test',
      bounds: MapBounds(west: -4, south: 39, east: -3, north: 40),
      minZoom: 8,
      maxZoom: 14,
      providerId: 'licensed-offline-provider',
      styleVersion: '1',
    );
    expect(region.isValid, isTrue);
  });

  test('alerts require traceable source URLs', () {
    final now = DateTime.utc(2026, 9, 23);
    final alert = OutdoorAlert(
      id: 'a1',
      authority: AlertAuthority.official,
      type: AlertType.storm,
      severity: AlertSeverity.caution,
      confidence: AlertConfidence.confirmed,
      title: 'Storm',
      sourceName: 'Official source',
      sourceUrl: 'https://example.invalid/source',
      issuedAt: now.subtract(const Duration(minutes: 1)),
      updatedAt: now,
      validUntil: now.add(const Duration(hours: 1)),
    );
    expect(alert.hasTraceableSource, isTrue);
    expect(alert.isValidAt(now), isTrue);
  });

  test('SOS expires and never remains valid past expiry', () {
    final captured = DateTime.utc(2026, 9, 23, 0, 0);
    final expires = captured.add(const Duration(minutes: 15));
    const emergency = EmergencySnapshot(
      type: EmergencyType.accident,
      position: GeoPoint(latitude: 40, longitude: -3),
      accuracyMeters: 8,
      capturedAt: DateTime.utc(2026, 9, 23),
      batteryPercent: 60,
    );
    final sosSnapshot = sos.SosSnapshot(
      state: sos.SosState.active,
      mode: sos.SosMode.unableToSpeak,
      emergency: emergency,
      precision: sos.LocationPrecision.approximate,
      capturedAt: captured,
      expiresAt: expires,
    );
    expect(sosSnapshot.isExpiredAt(expires), isTrue);
    expect(sosSnapshot.isExpiredAt(captured), isFalse);
  });

  test('elevation profile reports usability from available samples', () {
    final profile = ElevationProfile(
      samples: const [ElevationSample(meters: null), ElevationSample(meters: 842)],
      quality: ElevationQuality.estimated,
      providerId: 'offline-dem',
      sourceTimestamp: DateTime.utc(2026, 9, 23),
    );
    expect(profile.isUsable, isTrue);
  });

  test('offline navigation detects off-route positions', () {
    final now = DateTime.utc(2026, 9, 23);
    final route = RoutingResult(
      legs: const [
        RouteLeg(
          distanceMeters: 111,
          durationSeconds: 120,
          geometry: [
            RouteWaypoint(latitude: 40, longitude: -3),
            RouteWaypoint(latitude: 40.001, longitude: -3),
          ],
        ),
      ],
      providerId: 'offline-route',
      sourceTimestamp: now,
    );
    const engine = OfflineNavigationEngine(offRouteThresholdMeters: 20);
    final state = engine.update(
      route: route,
      position: const RouteWaypoint(latitude: 40.01, longitude: -3),
    );
    expect(state.offRoute, isTrue);
    expect(state.instruction.type, NavigationInstructionType.offRoute);
  });
}
