import '../contracts/platform_services.dart';

/// Provider-neutral live-data gateway. Concrete connectors belong in the
/// infrastructure layer and must preserve provenance and expiry metadata.
abstract interface class SourceGateway {
  Future<WeatherSnapshot> weatherAt(GeoPoint point);
  Future<List<LiveAlert>> alertsAt(GeoPoint point);
}

final class LiveAlert {
  const LiveAlert({
    required this.id,
    required this.title,
    required this.source,
    required this.confidence,
    required this.publishedAt,
    this.expiresAt,
    this.url,
  });

  final String id;
  final String title;
  final String source;
  final DataConfidence confidence;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final String? url;
}

/// Registry entry used by the backend/source-ingestion layer. It deliberately
/// stores provenance rather than copying authoritative datasets into the app.
final class SourceDefinition {
  const SourceDefinition({
    required this.key,
    required this.authority,
    required this.license,
    required this.attribution,
    required this.updateInterval,
    required this.enabled,
  });

  final String key;
  final String authority;
  final String license;
  final String attribution;
  final Duration updateInterval;
  final bool enabled;
}

final class SpainOutdoorSources {
  static const aemet = SourceDefinition(
    key: 'aemet_opendata',
    authority: 'AEMET',
    license: 'AEMET OpenData terms',
    attribution: 'Agencia Estatal de Meteorología (AEMET)',
    updateInterval: Duration(minutes: 15),
    enabled: true,
  );

  static const miteco = SourceDefinition(
    key: 'miteco_open_data',
    authority: 'MITECO',
    license: 'MITECO Open Data terms',
    attribution: 'Ministerio para la Transición Ecológica y el Reto Demográfico',
    updateInterval: Duration(hours: 1),
    enabled: true,
  );

  static const ignCnig = SourceDefinition(
    key: 'ign_cnig',
    authority: 'IGN/CNIG',
    license: 'IGN/CNIG data terms',
    attribution: 'Instituto Geográfico Nacional / CNIG',
    updateInterval: Duration(days: 1),
    enabled: true,
  );

  static const protectionCivil = SourceDefinition(
    key: 'proteccion_civil',
    authority: 'Protección Civil',
    license: 'Official source terms',
    attribution: 'Protección Civil',
    updateInterval: Duration(minutes: 5),
    enabled: true,
  );

  static const all = <SourceDefinition>[aemet, miteco, ignCnig, protectionCivil];
}
