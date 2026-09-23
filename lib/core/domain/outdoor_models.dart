/// Core domain models shared by route, safety, nature and offline features.
///
/// These models intentionally contain no Flutter dependencies so they can be
/// reused by mobile, desktop, web and future background services.
library;

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  Map<String, double> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

enum DataConfidence { official, verified, community, estimated, stale }

class DataProvenance {
  const DataProvenance({
    required this.source,
    required this.updatedAt,
    required this.confidence,
    this.license,
  });

  final String source;
  final DateTime updatedAt;
  final DataConfidence confidence;
  final String? license;

  bool get isStale => confidence == DataConfidence.stale;
}

enum OutdoorRiskLevel { low, caution, high, extreme, unknown }

class OutdoorRisk {
  const OutdoorRisk({
    required this.level,
    required this.title,
    required this.reason,
    this.provenance,
  });

  final OutdoorRiskLevel level;
  final String title;
  final String reason;
  final DataProvenance? provenance;
}

class RouteSummary {
  const RouteSummary({
    required this.id,
    required this.name,
    required this.distanceMeters,
    required this.elevationGainMeters,
    required this.estimatedMinutes,
    this.petFriendly = false,
    this.risk,
  });

  final String id;
  final String name;
  final double distanceMeters;
  final double elevationGainMeters;
  final int estimatedMinutes;
  final bool petFriendly;
  final OutdoorRisk? risk;
}

enum EmergencyType {
  accident,
  lost,
  medical,
  fire,
  wildlife,
  weather,
  pet,
  unableToSpeak,
  other,
}

enum EmergencyConnectivity {
  online,
  offline,
  unknown,
}

class EmergencySnapshot {
  const EmergencySnapshot({
    required this.type,
    required this.position,
    required this.accuracyMeters,
    required this.capturedAt,
    required this.batteryPercent,
    this.altitudeMeters,
    this.connectivity = EmergencyConnectivity.unknown,
  });

  final EmergencyType type;
  final GeoPoint position;
  final double accuracyMeters;
  final DateTime capturedAt;
  final int batteryPercent;
  final double? altitudeMeters;
  final EmergencyConnectivity connectivity;
}

class PetProfile {
  const PetProfile({
    required this.id,
    required this.name,
    required this.size,
    this.ageYears,
    this.activityLevel = 'normal',
  });

  final String id;
  final String name;
  final String size;
  final double? ageYears;
  final String activityLevel;
}

class WildlifeEncounterGuidance {
  const WildlifeEncounterGuidance({
    required this.species,
    required this.actions,
    required this.avoid,
    this.provenance,
  });

  final String species;
  final List<String> actions;
  final List<String> avoid;
  final DataProvenance? provenance;
}
