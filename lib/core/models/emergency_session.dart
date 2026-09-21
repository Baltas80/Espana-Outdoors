enum EmergencyState { idle, preparing, active, resolved, expired }

enum LocationPrecision { approximate, precise }

class EmergencySession {
  const EmergencySession({
    required this.id,
    required this.startedAt,
    required this.expiresAt,
    this.state = EmergencyState.idle,
    this.locationPrecision = LocationPrecision.precise,
  });

  final String id;
  final DateTime startedAt;
  final DateTime expiresAt;
  final EmergencyState state;
  final LocationPrecision locationPrecision;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
