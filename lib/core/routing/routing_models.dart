/// Provider-neutral routing and elevation contracts.
library;

class RouteWaypoint {
  const RouteWaypoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

enum RoutingProfile { hiking, cycling, trailRunning, walking }

class RoutingRequest {
  const RoutingRequest({
    required this.waypoints,
    this.profile = RoutingProfile.hiking,
    this.allowUnpaved = true,
  });

  final List<RouteWaypoint> waypoints;
  final RoutingProfile profile;
  final bool allowUnpaved;

  bool get isValid =>
      waypoints.length >= 2 &&
      waypoints.every(
        (point) =>
            point.latitude >= -90 &&
            point.latitude <= 90 &&
            point.longitude >= -180 &&
            point.longitude <= 180,
      );
}

class RouteLeg {
  const RouteLeg({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
    this.elevationGainMeters,
    this.elevationLossMeters,
  });

  final double distanceMeters;
  final double durationSeconds;
  final List<RouteWaypoint> geometry;
  final double? elevationGainMeters;
  final double? elevationLossMeters;
}

class RoutingResult {
  const RoutingResult({
    required this.legs,
    required this.providerId,
    required this.sourceTimestamp,
  });

  final List<RouteLeg> legs;
  final String providerId;
  final DateTime sourceTimestamp;

  double get distanceMeters =>
      legs.fold(0, (sum, leg) => sum + leg.distanceMeters);

  double get durationSeconds =>
      legs.fold(0, (sum, leg) => sum + leg.durationSeconds);
}
