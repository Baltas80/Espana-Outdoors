import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import 'waypoint.dart';

class WaypointNavigationSnapshot {
  const WaypointNavigationSnapshot({
    required this.distanceMeters,
    required this.bearingDegrees,
    required this.relativeBearingDegrees,
    required this.positionAccuracyMeters,
    required this.isUsable,
    this.reason,
  });

  final double distanceMeters;
  final double bearingDegrees;
  final double relativeBearingDegrees;
  final double positionAccuracyMeters;
  final bool isUsable;
  final String? reason;

  bool get arrived => isUsable && distanceMeters <= 20;
}

/// Calculates direct bearing/distance to a saved waypoint.
///
/// It intentionally does not replace the routing engine. It is useful for
/// off-road navigation and remains available without a route network.
/// Poor or stale GPS fixes are rejected instead of presenting false precision.
WaypointNavigationSnapshot calculateWaypointNavigation({
  required Position position,
  required OutdoorWaypoint waypoint,
  double maximumAccuracyMeters = 100,
  Duration maximumAge = const Duration(seconds: 30),
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final age = currentTime.difference(position.timestamp).abs();
  final accuracy = position.accuracy;
  final accurateEnough = accuracy.isFinite && accuracy >= 0 && accuracy <= maximumAccuracyMeters;
  final freshEnough = age <= maximumAge;
  final usable = accurateEnough && freshEnough;

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
    positionAccuracyMeters: accuracy,
    isUsable: usable,
    reason: usable
        ? null
        : (!accurateEnough ? 'Precisión GPS insuficiente.' : 'Lectura GPS antigua.'),
  );
}

double _radians(double value) => value * math.pi / 180;
double _degrees(double value) => value * 180 / math.pi;
