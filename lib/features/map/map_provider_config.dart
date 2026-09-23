/// Provider metadata kept in one place for development-only online maps
/// and attribution checks. Production map rendering is handled by MapLibre
/// through the configured first-party/licensed vector tile provider.
final class MapProviderConfig {
  const MapProviderConfig({
    required this.tileUrlTemplate,
    required this.attribution,
    required this.userAgent,
  });

  final String tileUrlTemplate;
  final String attribution;
  final String userAgent;

  static const openStreetMapDevelopment = MapProviderConfig(
    tileUrlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
    userAgent: 'EspanaOutdoor/0.1 (+https://github.com/Baltas80/Espana-Outdoors)',
  );
}
