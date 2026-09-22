/// Safety-first SOS contracts. Emergency payloads must be minimal and expire.
library;

import '../domain/outdoor_models.dart';

enum SosMode { normal, unableToSpeak }
enum SosState { idle, preparing, active, cancelled, expired, failed }

enum LocationPrecision { exact, approximate }

class SosSnapshot {
  const SosSnapshot({
    required this.state,
    required this.mode,
    required this.emergency,
    required this.precision,
    required this.capturedAt,
    required this.expiresAt,
    this.networkAvailable,
    this.batteryPercent,
  });

  final SosState state;
  final SosMode mode;
  final EmergencySnapshot emergency;
  final LocationPrecision precision;
  final DateTime capturedAt;
  final DateTime expiresAt;
  final bool? networkAvailable;
  final int? batteryPercent;

  bool isExpiredAt(DateTime now) => !expiresAt.isAfter(now);
}

abstract interface class EmergencyService {
  Future<SosSnapshot> prepareSos({
    required EmergencyType type,
    required EmergencySnapshot snapshot,
    required SosMode mode,
    required DateTime expiresAt,
  });

  Future<void> cancelSos(String incidentId);

  Future<void> expireSos(String incidentId);
}
