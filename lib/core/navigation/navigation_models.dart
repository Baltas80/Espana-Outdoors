/// Offline-first navigation contracts. No concrete map or routing vendor is exposed.
library;

class NavigationPosition {
  const NavigationPosition({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracyMeters,
    this.altitudeMeters,
    this.bearingDegrees,
    this.speedMetersPerSecond,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double? accuracyMeters;
  final double? altitudeMeters;
  final double? bearingDegrees;
  final double? speedMetersPerSecond;
}

enum NavigationState { idle, navigating, paused, offRoute, completed }

enum NavigationInstructionKind { continueStraight, turnLeft, turnRight, arrive, offRoute, warning }

class NavigationInstruction {
  const NavigationInstruction({
    required this.kind,
    required this.distanceMeters,
    required this.text,
  });

  final NavigationInstructionKind kind;
  final double distanceMeters;
  final String text;
}

class NavigationSnapshot {
  const NavigationSnapshot({
    required this.state,
    required this.position,
    this.distanceRemainingMeters,
    this.distanceOffRouteMeters,
    this.instruction,
  });

  final NavigationState state;
  final NavigationPosition position;
  final double? distanceRemainingMeters;
  final double? distanceOffRouteMeters;
  final NavigationInstruction? instruction;
}
