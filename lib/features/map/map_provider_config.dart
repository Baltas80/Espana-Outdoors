class MapProviderConfig {
  const MapProviderConfig({
    required this.tileUrlTemplate,
    required this.attribution,
    this.userAgent = 'EspanaOutdoor/0.1',
  });

  final String tileUrlTemplate;
  final String attribution;
  final String userAgent;

  /// Provider configuration is injected rather than hard-coded into features.
  /// Production deployments must use a provider whose terms and capacity fit
  /// the expected traffic and must retain required attribution.
  static const openStreetMap = MapProviderConfig(
    tileUrlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
  );
}
