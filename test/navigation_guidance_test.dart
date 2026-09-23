import 'package:espana_outdoors/core/contracts/routing_service.dart';
import 'package:espana_outdoors/core/domain/outdoor_models.dart';
import 'package:espana_outdoors/core/navigation/navigation_guidance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

RouteResult _route() => const RouteResult(
      points: [
        LatLng(40.0000, -3.0000),
        LatLng(40.0005, -3.0000),
        LatLng(40.0010, -3.0000),
        LatLng(40.0015, -3.0000),
      ],
      durationSeconds: 300,
      steps: [
        RouteStep(
          instruction: 'Gira a la derecha',
          beginShapeIndex: 2,
          endShapeIndex: 3,
          distanceMeters: 50,
          durationSeconds: 30,
        ),
      ],
    );

void main() {
  const engine = NavigationGuidanceEngine();

  test('reports on-route guidance with the next real maneuver', () {
    final result = engine.evaluate(
      route: _route(),
      position: const GeoPoint(latitude: 40.0006, longitude: -3.00002),
      accuracyMeters: 5,
    );

    expect(result.status, NavigationGuidanceStatus.onRoute);
    expect(result.distanceFromRouteMeters, lessThan(10));
    expect(result.nextStep?.instruction, 'Gira a la derecha');
    expect(result.progressFraction, greaterThan(0.2));
  });

  test('reports approaching turn from real shape indexes', () {
    final result = engine.evaluate(
      route: _route(),
      position: const GeoPoint(latitude: 40.0009, longitude: -3.00001),
      accuracyMeters: 5,
    );

    expect(result.status, NavigationGuidanceStatus.approachingTurn);
    expect(result.distanceToNextStepMeters, lessThan(60));
  });

  test('reports poor GPS before declaring off-route', () {
    final result = engine.evaluate(
      route: _route(),
      position: const GeoPoint(latitude: 40.0005, longitude: -3.0004),
      accuracyMeters: 120,
    );

    expect(result.status, NavigationGuidanceStatus.gpsPoor);
  });

  test('reports off-route when GPS is trustworthy and route separation is large', () {
    final result = engine.evaluate(
      route: _route(),
      position: const GeoPoint(latitude: 40.0010, longitude: -3.0010),
      accuracyMeters: 5,
    );

    expect(result.status, NavigationGuidanceStatus.offRoute);
    expect(result.isOffRoute, isTrue);
    expect(
      result.distanceFromRouteMeters,
      greaterThan(result.offRouteThresholdMeters),
    );
  });

  test('reports arrival near the route end', () {
    final result = engine.evaluate(
      route: _route(),
      position: const GeoPoint(latitude: 40.0015, longitude: -3.00001),
      accuracyMeters: 5,
    );

    expect(result.status, NavigationGuidanceStatus.arrived);
  });
}
