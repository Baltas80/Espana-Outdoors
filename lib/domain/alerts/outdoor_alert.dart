enum OutdoorAlertLevel { information, precaution, danger, emergency }

enum OutdoorAlertOrigin { official, espanaOutdoor }

/// Normalized alert contract. Concrete adapters must provide provenance and
/// validity; the UI must never fabricate an active alert.
final class OutdoorAlert {
  const OutdoorAlert({
    required this.id,
    required this.title,
    required this.level,
    required this.origin,
    required this.sourceName,
    required this.sourceUrl,
    required this.issuedAt,
    this.updatedAt,
    this.validUntil,
    this.areaName,
    this.summary,
  });

  final String id;
  final String title;
  final OutdoorAlertLevel level;
  final OutdoorAlertOrigin origin;
  final String sourceName;
  final String sourceUrl;
  final DateTime issuedAt;
  final DateTime? updatedAt;
  final DateTime? validUntil;
  final String? areaName;
  final String? summary;

  bool isValidAt(DateTime instant) =>
      validUntil == null || instant.isBefore(validUntil!);
}
