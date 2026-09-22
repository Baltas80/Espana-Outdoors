/// Provider-neutral contract for official and España Outdoor alerts.
library;

import '../domain/outdoor_models.dart';

class AlertQuery {
  const AlertQuery({required this.center, this.radiusMeters = 50000});
  final GeoPoint center;
  final double radiusMeters;
}

enum AlertOrigin { official, espanaOutdoor }
enum AlertKind { fire, flood, storm, wind, snow, heat, cold, earthquake, tsunami, volcano, landslide, other }

class OutdoorAlert {
  const OutdoorAlert({required this.id, required this.origin, required this.kind, required this.title, required this.reason, required this.provenance, this.validUntil});
  final String id;
  final AlertOrigin origin;
  final AlertKind kind;
  final String title;
  final String reason;
  final DataProvenance provenance;
  final DateTime? validUntil;
  bool get isExpired => validUntil != null && validUntil!.isBefore(DateTime.now().toUtc());
}

abstract interface class AlertService {
  String get providerId;
  Future<List<OutdoorAlert>> alerts(AlertQuery query);
}
