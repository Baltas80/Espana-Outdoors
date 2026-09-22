/// Emergency contracts with explicit data minimisation and expiry.
library;

enum LocationPrecision { exact, approximate }

enum EmergencyMode { sos, cannotTalk }

class EmergencyLocation {
  const EmergencyLocation({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    required this.precision,
    this.accuracyMeters,
    this.altitudeMeters,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final LocationPrecision precision;
  final double? accuracyMeters;
  final double? altitudeMeters;
}

class EmergencySnapshot {
  const EmergencySnapshot({
    required this.mode,
    required this.location,
    required this.expiresAt,
    this.batteryPercent,
    this.networkAvailable,
  });

  final EmergencyMode mode;
  final EmergencyLocation location;
  final DateTime expiresAt;
  final int? batteryPercent;
  final bool? networkAvailable;

  bool isExpired(DateTime now) => !expiresAt.isAfter(now);
}

abstract interface class EmergencyService {
  Future<EmergencySnapshot> activate(EmergencyMode mode);
  Future<void> shareWithTrustedContact(String contactId, EmergencySnapshot snapshot);
  Future<void> end();
}
