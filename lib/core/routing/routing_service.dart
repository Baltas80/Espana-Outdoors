import 'routing_models.dart';

/// Routing abstraction used by discovery, navigation and route recalculation.
///
/// Provider-specific SDKs or hosted engines must remain behind this interface.
abstract interface class RoutingService {
  String get providerId;

  Future<RoutingResult> calculateRoute(RoutingRequest request);

  Future<List<double?>> sampleElevation(List<RouteWaypoint> points);
}
