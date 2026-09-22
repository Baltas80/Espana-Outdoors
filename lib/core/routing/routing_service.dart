import 'routing_models.dart';

/// Routing abstraction used by discovery, navigation and route recalculation.
abstract interface class RoutingService {
  String get providerId;

  Future<RoutingResult> calculateRoute(RoutingRequest request);

  Future<List<double?>> sampleElevation(List<RouteWaypoint> points);
}
