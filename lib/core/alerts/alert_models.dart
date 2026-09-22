/// Provider-neutral live risk alert contracts.
library;

enum AlertAuthority { official, espanaOutdoor }

enum AlertSeverity { information, caution, danger, emergency }

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
  closure,
  other,
}

enum AlertConfidence { confirmed, probable, preliminary, unknown }

class OutdoorAlert {
  const OutdoorAlert({
    required this.id,
    required this.authority,
    required this.type,
    required this.severity,
    required this.confidence,
    required this.title,
    required this.sourceName,
    required this.sourceUrl,
    required this.issuedAt,
    required this.updatedAt,
    required this.validUntil,
    this.description,
    this.sourceId,
    this.regionId,
  });

  final String id;
  final AlertAuthority authority;
  final AlertType type;
  final AlertSeverity severity;
  final AlertConfidence confidence;
  final String title;
  final String sourceName;
  final String sourceUrl;
  final DateTime issuedAt;
  final DateTime updatedAt;
  final DateTime validUntil;
  final String? description;
  final String? sourceId;
  final String? regionId;

  bool isValidAt(DateTime now) =>
      !issuedAt.isAfter(now) &&
      !updatedAt.isAfter(now) &&
      validUntil.isAfter(now);

  bool get hasTraceableSource =>
      sourceName.trim().isNotEmpty &&
      Uri.tryParse(sourceUrl)?.hasScheme == true;

  bool get isOfficial => authority == AlertAuthority.official;
}
