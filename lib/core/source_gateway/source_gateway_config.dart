/// Runtime configuration for the first-party live-data gateway.
///
/// No provider API key is accepted here. The gateway URL is an app runtime
/// endpoint and the access token is supplied separately by OIDC.
final class SourceGatewayConfig {
  const SourceGatewayConfig({required this.baseUri});

  final Uri baseUri;

  bool get isConfigured =>
      baseUri.scheme == 'https' && baseUri.host.isNotEmpty;

  static SourceGatewayConfig fromEnvironment() {
    const raw = String.fromEnvironment('SOURCE_GATEWAY_BASE_URL');
    final uri = Uri.tryParse(raw);
    return SourceGatewayConfig(baseUri: uri ?? Uri());
  }

  void validate() {
    if (!isConfigured) {
      throw StateError(
        'SOURCE_GATEWAY_BASE_URL is missing or is not an HTTPS URL.',
      );
    }
  }
}
