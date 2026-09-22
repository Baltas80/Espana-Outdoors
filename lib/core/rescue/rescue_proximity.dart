import 'dart:math' as math;

import '../domain/outdoor_models.dart';
import 'rescue_link_policy.dart';

class RescueProximity {
  const RescueProximity();

  bool isWithinRadius({
    required GeoPoint alert,
    required GeoPoint responder,
    required RescueLinkPolicy policy,
  }) {
    return distanceMeters(alert, responder) <= policy.radiusMeters;
  }

  double distanceMeters(GeoPoint a, GeoPoint b) {
    const radius = 6371008.8;
    double rad(double value) => value * math.pi / 180;

    final dLat = rad(b.latitude - a.latitude);
    final dLon = rad(b.longitude - a.longitude);
    final lat1 = rad(a.latitude);
    final lat2 = rad(b.latitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
    return radius * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }
}
