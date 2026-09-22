/// Deterministic, network-independent navigation calculations.
library;

import 'dart:math' as math;

import 'navigation_models.dart';
import 'routing_models.dart';

class OfflineNavigationEngine {
  const OfflineNavigationEngine({this.offRouteThresholdMeters = 45});

  final double offRouteThresholdMeters;

  NavigationState update({
    required RoutingResult route,
    required RouteWaypoint position,
  }) {
    final geometry = route.legs.expand((leg) => leg.geometry).toList(growable: false);
    if (geometry.length < 2) {
      return NavigationState(
        route: route,
        position: position,
        remainingDistanceMeters: 0,
        remainingDurationSeconds: 0,
        offRoute: true,
        instruction: const NavigationInstruction(
          type: NavigationInstructionType.unavailable,
          text: 'Navegación no disponible',
        ),
      );
    }

    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    for (var i = 0; i < geometry.length; i++) {
      final distance = _distanceMeters(position, geometry[i]);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }

    var remaining = 0.0;
    for (var i = nearestIndex; i < geometry.length - 1; i++) {
      remaining += _distanceMeters(geometry[i], geometry[i + 1]);
    }

    final fraction = route.distanceMeters <= 0
        ? 0.0
        : (remaining / route.distanceMeters).clamp(0.0, 1.0);
    final instruction = nearestDistance > offRouteThresholdMeters
        ? const NavigationInstruction(
            type: NavigationInstructionType.offRoute,
            text: 'Fuera de ruta',
          )
        : nearestIndex >= geometry.length - 2
            ? const NavigationInstruction(
                type: NavigationInstructionType.arrive,
                text: 'Llegando al destino',
              )
            : NavigationInstruction(
                type: NavigationInstructionType.continueStraight,
                text: 'Continúa por la ruta',
                distanceMeters: _distanceMeters(position, geometry[nearestIndex + 1]),
              );

    return NavigationState(
      route: route,
      position: position,
      remainingDistanceMeters: remaining,
      remainingDurationSeconds: route.durationSeconds * fraction,
      offRoute: nearestDistance > offRouteThresholdMeters,
      instruction: instruction,
    );
  }

  static double _distanceMeters(RouteWaypoint a, RouteWaypoint b) {
    const earthRadius = 6371008.8;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = lat2 - lat1;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }
}
