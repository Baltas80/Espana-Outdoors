class MapProviderConfig {
  const MapProviderConfig({
    required this.tileUrlTemplate,
    required this.attribution,
    this.userAgent = 'EspanaOutdoor/0.1',
  });

  final String tileUrlTemplate;
  final String attribution;
  final String userAgent;

  /// Primary Spain-focused online base map.
  ///
  /// The IGN publishes this raster tile service and documents CC BY 4.0
  /// terms for the associated API-Maps service. Provider capacity/terms still
  /// need to be validated for the final production traffic profile.
  static const ignBase = MapProviderConfig(
    tileUrlTemplate:
        'https://tms-ign-base.idee.es/1.0.0/IGNBaseTodo/{z}/{x}/{-y}.jpeg',
    attribution: '© Instituto Geográfico Nacional (IGN-CNIG) · CC BY 4.0',
    userAgent: 'EspanaOutdoor/0.1',
  );

  /// Orthophoto layer for a future map-mode switch.
  static const ignOrtho = MapProviderConfig(
    tileUrlTemplate:
        'https://tms-pnoa-ma.idee.es/1.0.0/pnoa-ma/{z}/{x}/{-y}.jpeg',
    attribution: '© Instituto Geográfico Nacional (IGN-CNIG) · CC BY 4.0',
    userAgent: 'EspanaOutdoor/0.1',
  );

  /// Neutral development fallback.
  ///
  /// Public OSM tiles are not used for bulk/offline downloads.
  static const openStreetMap = MapProviderConfig(
    tileUrlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
    userAgent: 'EspanaOutdoor/0.1',
  );

  static const onlineDefault = ignBase;
}
