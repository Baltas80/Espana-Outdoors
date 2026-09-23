import 'data_provenance.dart';

enum AlertSeverity { info, advisory, warning, severe, extreme }

enum AlertType {
  wildfire,
  flood,
  storm,
  wind,
  snow,
  ice,
  heat,
  cold,
  earthquake,
  tsunami,
  volcanic,
  landslide,
  other,
}

/// Normalized alert model shared by official feeds and product warnings.
/// Product-generated warnings must never be represented as official alerts.
class OfficialAlert {
  const OfficialAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.source,
    required this.provenance,
    required this.issuedAt,
    required this.validFrom,
    required this.validUntil,
    this.description,
    this.areaName,
    this.official = true,
  });

  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String? description;
  final String? areaName;
  final String source;
  final DataProvenance provenance;
  final DateTime issuedAt;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool official;

  bool get isActive {
    final now = DateTime.now().toUtc();
    return !now.isBefore(validFrom.toUtc()) && now.isBefore(validUntil.toUtc());
  }
}
