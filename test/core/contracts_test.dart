import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/core/alerts/alert_models.dart';
import 'package:espana_outdoors/core/emergency/sos_models.dart';
import 'package:espana_outdoors/core/map/offline_map_models.dart';
import 'package:espana_outdoors/core/navigation/navigation_models.dart';
import 'package:espana_outdoors/core/routing/routing_models.dart';

void main() {
  test('routing request validates coordinates and minimum waypoints', () {
    expect(
      const RoutingRequest(waypoints: [RouteWaypoint(latitude: 40, longitude: -3)]).isValid,
      isFalse,
    );
    expect(
      const RoutingRequest(waypoints: [
        RouteWaypoint(latitude: 40, longitude: -3),
        RouteWaypoint(latitude: 41, longitude: -4),
      ]).isValid,
      isTrue,
    );
  });

  test('offline progress clamps fraction', () {
    expect(
      const OfflineMapProgress(
        regionId: 'x',
        state: OfflineDownloadState.downloading,
        completedBytes: 150,
        totalBytes: 100,
      ).fraction,
      1,
    );
  });

  test('official alert exposes traceable source', () {
    final alert = OutdoorAlert(
      id: 'a',
      authority: AlertAuthority.official,
      type: AlertType.wildfire,
      severity: AlertSeverity.danger,
      confidence: AlertConfidence.confirmed,
      title: 'Test',
      sourceName: 'Official source',
      sourceUrl: 'https://example.com/alert',
      issuedAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      validUntil: DateTime(2027, 1, 1),
    );
    expect(alert.hasTraceableSource, isTrue);
    expect(alert.isOfficial, isTrue);
  });

  test('expired emergency snapshot is detectable', () {
    final snapshot = EmergencySnapshot(
      mode: EmergencyMode.sos,
      location: const EmergencyLocation(
        latitude: 40,
        longitude: -3,
        recordedAt: DateTime(2026, 1, 1),
        precision: LocationPrecision.approximate,
      ),
      expiresAt: DateTime(2026, 1, 2),
    );
    expect(snapshot.isExpired(DateTime(2026, 1, 3)), isTrue);
  });

  test('navigation snapshot can represent off-route state', () {
    final snapshot = NavigationSnapshot(
      state: NavigationState.offRoute,
      position: NavigationPosition(
        latitude: 40,
        longitude: -3,
        recordedAt: DateTime(2026, 1, 1),
      ),
      distanceOffRouteMeters: 120,
    );
    expect(snapshot.distanceOffRouteMeters, 120);
  });
}
