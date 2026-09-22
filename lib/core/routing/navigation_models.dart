/// Offline-safe navigation state. No network/provider dependency.
library;

import 'routing_models.dart';

enum NavigationInstructionType { start, continueStraight, turnLeft, turnRight, arrive, offRoute, rerouting, unavailable }

class NavigationInstruction {
  const NavigationInstruction({
    required this.type,
    required this.text,
    this.distanceMeters,
  });

  final NavigationInstructionType type;
  final String text;
  final double? distanceMeters;
}

class NavigationState {
  const NavigationState({
    required this.route,
    required this.position,
    required this.remainingDistanceMeters,
    required this.remainingDurationSeconds,
    required this.offRoute,
    required this.instruction,
  });

  final RoutingResult route;
  final RouteWaypoint position;
  final double remainingDistanceMeters;
  final double remainingDurationSeconds;
  final bool offRoute;
  final NavigationInstruction instruction;
}
