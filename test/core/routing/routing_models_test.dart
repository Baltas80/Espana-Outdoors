import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/core/routing/routing_models.dart';

void main() {
  test('routing request rejects invalid coordinates and too few points', () {
    expect(
      const RoutingRequest(
        waypoints: [RouteWaypoint(latitude: 42, longitude: 2)],
      ).isValid,
      isFalse,
    );

    expect(
      const RoutingRequest(
        waypoints: [
          RouteWaypoint(latitude: 95, longitude: 2),
          RouteWaypoint(latitude: 42, longitude: 3),
        ],
      ).isValid,
      isFalse,
    );
  });

  test('routing result aggregates leg distance and duration', () {
    final result = RoutingResult(
      providerId: 'test',
      sourceTimestamp: DateTime.utc(2026, 9, 22),
      legs: const [
        RouteLeg(
          distanceMeters: 1000,
          durationSeconds: 600,
          geometry: [],
        ),
        RouteLeg(
          distanceMeters: 500,
          durationSeconds: 300,
          geometry: [],
        ),
      ],
    );

    expect(result.distanceMeters, 1500);
    expect(result.durationSeconds, 900);
  });
}
