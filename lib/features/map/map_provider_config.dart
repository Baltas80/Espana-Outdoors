class MapProviderConfig {
  const MapProviderConfig({
    required this.tileUrlTemplate,
    required this.attribution,
    this.userAgent = 'EspanaOutdoor/0.1',
  });

  final String tileUrlTemplate;
  final String attribution;
  final String userAgent;

  bool get isConfigured => tileUrlTemplate.isNotEmpty;

  /// Runtime-selected provider. Production must inject a provider endpoint
  /// owned/contracted by the deployment. The OSM raster fallback is explicitly
  /// limited to development so the app cannot silently become a bulk tile
  /// consumer in production.
  static MapProviderConfig fromEnvironment() {
    const tileUrl = String.fromEnvironment('MAP_TILE_URL');
    const attribution = String.fromEnvironment('MAP_ATTRIBUTION');
    const appEnv = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );

    if (tileUrl.isNotEmpty) {
      return MapProviderConfig(
        tileUrlTemplate: tileUrl,
        attribution: attribution.isEmpty ? 'Map data provider' : attribution,
      );
    }

    if (appEnv != 'production') return openStreetMapDevelopment;

    return const MapProviderConfig(tileUrlTemplate: '', attribution: '');
  }

  static const openStreetMapDevelopment = MapProviderConfig(
    tileUrlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
  );
}
