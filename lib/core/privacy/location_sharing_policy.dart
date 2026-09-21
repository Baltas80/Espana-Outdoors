enum LocationSharePrecision { exact, approximate }

class LocationShareGrant {
  const LocationShareGrant({
    required this.recipientId,
    required this.precision,
    required this.expiresAt,
  });

  final String recipientId;
  final LocationSharePrecision precision;
  final DateTime expiresAt;

  bool isActive(DateTime now) => now.isBefore(expiresAt);
}

class LocationSharingPolicy {
  const LocationSharingPolicy._();

  static LocationShareGrant temporaryEmergencyGrant({
    required String recipientId,
    required DateTime now,
  }) {
    return LocationShareGrant(
      recipientId: recipientId,
      precision: LocationSharePrecision.exact,
      expiresAt: now.add(const Duration(hours: 1)),
    );
  }

  static LocationShareGrant nearbyRescueGrant({
    required String recipientId,
    required DateTime now,
  }) {
    return LocationShareGrant(
      recipientId: recipientId,
      precision: LocationSharePrecision.approximate,
      expiresAt: now.add(const Duration(minutes: 30)),
    );
  }
}
