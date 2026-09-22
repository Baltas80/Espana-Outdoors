import 'package:espana_outdoors/core/alerts/alert_service.dart';
import 'package:espana_outdoors/core/domain/outdoor_models.dart';
import 'package:espana_outdoors/core/map/map_service.dart';
import 'package:espana_outdoors/core/routing/routing_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('map bounds reject invalid geographic ranges', () {
    const bounds = MapBounds(west: -181, south: 0, east: 10, north: 10);
    expect(bounds.isValid, isFalse);
  });

  test('routing contract keeps outdoor profile provider-neutral', () {
    const request = RouteRequest(
      points: [GeoPoint(latitude: 40, longitude: -3)],
      profile: RoutingProfile(id: 'hiking'),
    );
    expect(request.profile.id, 'hiking');
    expect(request.profile.allowTrails, isTrue);
  });

  test('expired alerts are detectable locally', () {
    final alert = OutdoorAlert(
      id: 'test',
      origin: AlertOrigin.official,
      kind: AlertKind.storm,
      title: 'Test',
      reason: 'Test',
      provenance: DataProvenance(
        source: 'test',
        updatedAt: DateTime.now().toUtc(),
        confidence: DataConfidence.official,
      ),
      validUntil: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    );
    expect(alert.isExpired, isTrue);
  });
}
