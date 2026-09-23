final class RescueLinkConfig {
  const RescueLinkConfig({
    required this.baseUrl,
    this.allowHttpForDevelopment = false,
  });

  final Uri baseUrl;
  final bool allowHttpForDevelopment;

  bool get isConfigured =>
      baseUrl.hasScheme && baseUrl.host.isNotEmpty;

  static RescueLinkConfig fromEnvironment() {
    const raw = String.fromEnvironment('RESCUE_LINK_BASE_URL');
    const allowHttp = String.fromEnvironment('ALLOW_HTTP_DEV');
    return RescueLinkConfig(
      baseUrl: Uri.tryParse(raw) ?? Uri(),
      allowHttpForDevelopment: allowHttp == 'true',
    );
  }
}