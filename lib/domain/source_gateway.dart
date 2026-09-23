import 'data_provenance.dart';
import 'official_alert.dart';
import '../core/contracts/platform_services.dart' as contracts;

class SourceHealth {
  const SourceHealth({
    required this.sourceId,
    required this.checkedAt,
    required this.available,
    required this.latency,
  });

  final String sourceId;
  final DateTime checkedAt;
  final bool available;
  final Duration latency;
}

abstract interface class SourceAdapter<T> {
  String get sourceId;
  String get sourceName;
  Future<T> fetch(contracts.GeoPoint point);
  Future<SourceHealth> healthCheck();
}

abstract interface class OfficialAlertSource {
  String get sourceId;
  Future<List<OfficialAlert>> activeAlerts(contracts.GeoPoint point);
  Future<SourceHealth> healthCheck();
}

/// Provider-neutral boundary for Spanish public data.
/// Adapters must preserve provenance and never fabricate unavailable data.
abstract interface class SourceGateway {
  Future<contracts.WeatherSnapshot> weatherAt(contracts.GeoPoint point);
  Future<List<OfficialAlert>> alertsAt(contracts.GeoPoint point);
  Future<List<SourceHealth>> health();
}
