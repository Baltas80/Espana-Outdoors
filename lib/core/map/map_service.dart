/// Provider-neutral map contracts.
///
/// Product features must depend on these contracts rather than a concrete
/// tile URL, renderer SDK or hosted map vendor.
library;

class MapBounds {
  const MapBounds({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  final double west;
  final double south;
  final double east;
  final double north;

  bool get isValid =>
      west >= -180 &&
      west <= 180 &&
      east >= -180 &&
      east <= 180 &&
      south >= -90 &&
      south <= 90 &&
      north >= -90 &&
      north <= 90 &&
      west <= east &&
      south <= north;
}

class OfflineMapRegion {
  const OfflineMapRegion({
    required this.id,
    required this.name,
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
    required this.providerId,
    required this.styleVersion,
  });

  final String id;
  final String name;
  final MapBounds bounds;
  final int minZoom;
  final int maxZoom;
  final String providerId;
  final String styleVersion;

  bool get isValid =>
      id.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      providerId.trim().isNotEmpty &&
      styleVersion.trim().isNotEmpty &&
      bounds.isValid &&
      minZoom >= 0 &&
      maxZoom >= minZoom;
}

abstract interface class MapService {
  String get providerId;

  Future<void> prepareOfflineRegion(OfflineMapRegion region);

  Future<void> pauseOfflineRegion(String regionId);

  Future<void> resumeOfflineRegion(String regionId);

  Future<void> deleteOfflineRegion(String regionId);
}
