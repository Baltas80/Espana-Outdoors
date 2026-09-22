/// Normalized alert domain model.
///
/// Provider adapters map official feeds and España Outdoor notices into this
/// model. UI and safety decisions must never depend on provider-specific
/// payloads.
library;

enum AlertOrigin { official, espanaOutdoor }

enum AlertSeverity { information, minor, moderate, severe, extreme }

enum AlertConfidence { unknown, low, medium, high }

enum AlertType {
  wildfire,
  flood,
  storm,
  wind,
  snow,
  heat,
  cold,
  earthquake,
  tsunami,
  volcano,
  landslide,
  other,
}

class OutdoorAlert {
  const OutdoorAlert({
    required this.id,
    required this.origin,
    required this.type,
    required this.title,
    required this.severity,
    required this.confidence,
    required this.source,
    required this.publishedAt,
    required this.updatedAt,
    this.validUntil,
    this.sourceUrl,
    this.description,
    this.areaName,
  });

  final String id;
  final AlertOrigin origin;
  final AlertType type;
  final String title;
  final AlertSeverity severity;
  final AlertConfidence confidence;
  final String source;
  final DateTime publishedAt;
  final DateTime updatedAt;
  final DateTime? validUntil;
  final String? sourceUrl;
  final String? description;
  final String? areaName;

  bool get isExpired =>
      validUntil != null && !validUntil!.toUtc().isAfter(DateTime.now().toUtc());

  bool get hasProvenance =>
      source.trim().isNotEmpty &&
      id.trim().isNotEmpty &&
      sourceUrl == null || sourceUrl!.trim().isNotEmpty;

  bool get isUsable {
    final now = DateTime.now().toUtc();
    return id.trim().isNotEmpty &&
        title.trim().isNotEmpty &&
        source.trim().isNotEmpty &&
        !updatedAt.toUtc().isAfter(now.add(const Duration(minutes: 5))) &&
        !isExpired;
  }
}

abstract interface class AlertService {
  Future<List<OutdoorAlert>> activeAlerts({
    required double latitude,
    required double longitude,
  });
}
