final class SourceGatewayConfig {
  const SourceGatewayConfig({required this.baseUri});

  final Uri? baseUri;

  bool get isConfigured => baseUri != null;

  static SourceGatewayConfig fromEnvironment() {
    const raw = String.fromEnvironment('SOURCE_GATEWAY_BASE_URL');
    if (raw.isEmpty) return const SourceGatewayConfig(baseUri: null);
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return const SourceGatewayConfig(baseUri: null);
    }
    return SourceGatewayConfig(baseUri: uri);
  }
}
