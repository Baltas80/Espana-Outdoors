import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/core/routing/routing_models.dart';

void main() {
  test('routing request accepts valid Spain coordinates', () {
    const request = RoutingRequest(
      waypoints: [
        RouteWaypoint(latitude: 40.4168, longitude: -3.7038),
        RouteWaypoint(latitude: 40.4180, longitude: -3.7050),
      ],
    );
    expect(request.isValid, isTrue);
  });
}
