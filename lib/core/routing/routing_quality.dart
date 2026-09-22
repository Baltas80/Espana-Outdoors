/// Normalized routing quality metadata, independent from a provider.
library;

enum RouteSurface { paved, gravel, dirt, rock, unknown }
enum RouteDataFreshness { fresh, stale, unknown }

class ElevationSample {
  const ElevationSample({
    required this.latitude,
    required this.longitude,
    required this.elevationMeters,
  });

  final double latitude;
  final double longitude;
  final double? elevationMeters;
}

class ElevationProfile {
  const ElevationProfile({
    required this.samples,
    required this.providerId,
    required this.freshness,
  });

  final List<ElevationSample> samples;
  final String providerId;
  final RouteDataFreshness freshness;
}

class RouteQuality {
  const RouteQuality({
    required this.providerId,
    required this.freshness,
    this.surface,
    this.coveragePercent,
    this.technicalDifficulty,
    this.exposureScore,
    this.isolationScore,
  });

  final String providerId;
  final RouteDataFreshness freshness;
  final RouteSurface? surface;
  final double? coveragePercent;
  final double? technicalDifficulty;
  final double? exposureScore;
  final double? isolationScore;
}
