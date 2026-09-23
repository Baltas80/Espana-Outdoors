
class GatewayConfig {
  const GatewayConfig._();

  static const endpoint = String.fromEnvironment(
    'ESPANA_OUTDOOR_GATEWAY_URL',
    defaultValue: '',
  );

  static Uri? get baseUri {
    final value = endpoint.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    return uri;
  }
}
