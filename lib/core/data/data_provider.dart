import '../domain/outdoor_models.dart';

/// Adapter contract for live or cached outdoor data providers.
///
/// Implementations may target AEMET, environmental authorities, OSM-derived
/// services or another licensed provider without coupling the UI to them.
abstract interface class OutdoorDataProvider {
  Future<List<OutdoorRisk>> risksNear(GeoPoint center);
  Future<List<RouteSummary>> routesNear(GeoPoint center);
}

abstract interface class WeatherProvider {
  Future<WeatherSnapshot> forecastAt(GeoPoint point);
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperatureC,
    required this.windKph,
    required this.precipitationProbability,
    required this.updatedAt,
    this.provenance,
  });

  final double temperatureC;
  final double windKph;
  final int precipitationProbability;
  final DateTime updatedAt;
  final DataProvenance? provenance;
}
