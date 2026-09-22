/// Provider-neutral routing and elevation contracts.
/// Product/UI code must not depend on a concrete routing provider.
library;

import '../domain/outdoor_models.dart';

class RoutingProfile {
  const RoutingProfile({required this.id, this.allowUnpaved = true, this.allowTrails = true});
  final String id;
  final bool allowUnpaved;
  final bool allowTrails;
}

class RouteRequest {
  const RouteRequest({required this.points, required this.profile});
  final List<GeoPoint> points;
  final RoutingProfile profile;
}

class RouteInstruction {
  const RouteInstruction({required this.text, required this.distanceMeters, required this.position});
  final String text;
  final double distanceMeters;
  final GeoPoint position;
}

class RouteResult {
  const RouteResult({required this.geometry, required this.distanceMeters, required this.elevationGainMeters, required this.instructions});
  final List<GeoPoint> geometry;
  final double distanceMeters;
  final double elevationGainMeters;
  final List<RouteInstruction> instructions;
}

abstract interface class RoutingService {
  String get providerId;
  Future<RouteResult> route(RouteRequest request);
  Future<RouteResult> matchTrack(List<GeoPoint> track);
}

class ElevationPoint {
  const ElevationPoint({required this.position, required this.elevationMeters});
  final GeoPoint position;
  final double elevationMeters;
}

abstract interface class ElevationService {
  String get providerId;
  Future<List<ElevationPoint>> elevation(List<GeoPoint> points);
}
