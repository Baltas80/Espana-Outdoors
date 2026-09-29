import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import 'waypoint.dart';

class WaypointNavigationSnapshot {
  const WaypointNavigationSnapshot({
    required this.distanceMeters,
    required this.bearingDegrees,
    required this.relativeBearingDegrees,
  });

  final double distanceMeters;
  final double bearingDegrees;
  final double relativeBearingDegrees;

  bool get arrived => distanceMeters <= 20;
}

/// Calculates a direct bearing/distance to a saved waypoint.
/// It intentionally does not replace the routing engine: it is useful when
/// following a waypoint off-road or with no route network available.
WaypointNavigationSnapshot calculateWaypointNavigation({
  required Position position,
  required OutdoorWaypoint waypoint,
}) {
  final distance = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    waypoint.latitude,
    waypoint.longitude,
  );

  final lat1 = _radians(position.latitude);
  final lat2 = _radians(waypoint.latitude);
  final deltaLon = _radians(waypoint.longitude - position.longitude);
  final y = math.sin(deltaLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);
  final bearing = (_degrees(math.atan2(y, x)) + 360) % 360;
  final heading = position.heading.isFinite && position.heading >= 0
      ? position.heading
      : bearing;
  final relative = ((bearing - heading + 540) % 360) - 180;

  return WaypointNavigationSnapshot(
    distanceMeters: distance,
    bearingDegrees: bearing,
    relativeBearingDegrees: relative,
  );
}

double _radians(double value) => value * math.pi / 180;
double _degrees(double value) => value * 180 / math.pi;
