/// Deterministic, network-independent navigation calculations.
library;

import 'dart:math' as math;

import '../navigation/navigation_models.dart';
import 'routing_models.dart';

class OfflineNavigationEngine {
  const OfflineNavigationEngine({this.offRouteThresholdMeters = 45});

  final double offRouteThresholdMeters;

  NavigationSnapshot update({
    required RoutingResult route,
    required RouteWaypoint position,
  }) {
    final recordedAt = DateTime.now().toUtc();
    final geometry =
        route.legs.expand((leg) => leg.geometry).toList(growable: false);

    final navigationPosition = NavigationPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      recordedAt: recordedAt,
    );

    if (geometry.length < 2) {
      return NavigationSnapshot(
        state: NavigationState.offRoute,
        position: navigationPosition,
        distanceRemainingMeters: 0,
        distanceOffRouteMeters: double.infinity,
        instruction: const NavigationInstruction(
          kind: NavigationInstructionKind.warning,
          distanceMeters: 0,
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
    final offRoute = nearestDistance > offRouteThresholdMeters;

    final instruction = offRoute
        ? const NavigationInstruction(
            kind: NavigationInstructionKind.offRoute,
            distanceMeters: 0,
            text: 'Fuera de ruta',
          )
        : nearestIndex >= geometry.length - 2
            ? const NavigationInstruction(
                kind: NavigationInstructionKind.arrive,
                distanceMeters: 0,
                text: 'Llegando al destino',
              )
            : NavigationInstruction(
                kind: NavigationInstructionKind.continueStraight,
                distanceMeters:
                    _distanceMeters(position, geometry[nearestIndex + 1]),
                text: 'Continúa por la ruta',
              );

    return NavigationSnapshot(
      state: offRoute
          ? NavigationState.offRoute
          : nearestIndex >= geometry.length - 2
              ? NavigationState.completed
              : NavigationState.navigating,
      position: navigationPosition,
      distanceRemainingMeters: remaining,
      distanceOffRouteMeters: offRoute ? nearestDistance : 0,
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
        math.cos(lat1) *
            math.cos(lat2) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }
}
