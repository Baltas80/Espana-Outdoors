import 'package:latlong2/latlong.dart';

class RouteRequest {
  const RouteRequest({required this.points, this.profile = 'hiking'});

  final List<LatLng> points;
  final String profile;
}

class RouteResult {
  const RouteResult({required this.points, this.distanceMeters, this.durationSeconds, this.ascentMeters, this.descentMeters});

  final List<LatLng> points;
  final double? distanceMeters;
  final double? durationSeconds;
  final double? ascentMeters;
  final double? descentMeters;
}

/// Provider-neutral outdoor routing boundary. The production adapter is expected
/// to delegate to a mature engine such as Valhalla rather than implement routing
/// algorithms in the application layer.
abstract interface class RoutingService {
  Future<RouteResult> route(RouteRequest request);
  Future<RouteResult> match(List<LatLng> track);
}
