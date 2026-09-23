/// Runtime OIDC configuration. No issuer, client secret or redirect is
/// hard-coded into the application.
final class OidcConfig {
  const OidcConfig({
    required this.issuer,
    required this.clientId,
    required this.redirectUrl,
    this.tenantId,
  });

  final Uri issuer;
  final String clientId;
  final String redirectUrl;
  final String? tenantId;

  bool get isConfigured =>
      issuer.hasScheme && issuer.host.isNotEmpty && clientId.isNotEmpty && redirectUrl.isNotEmpty;

  static OidcConfig fromEnvironment() {
    const issuer = String.fromEnvironment('OIDC_ISSUER');
    const clientId = String.fromEnvironment('OIDC_CLIENT_ID');
    const redirectUrl = String.fromEnvironment('OIDC_REDIRECT_URI');
    const tenantId = String.fromEnvironment('OIDC_TENANT_ID');

    return OidcConfig(
      issuer: Uri.tryParse(issuer) ?? Uri(),
      clientId: clientId,
      redirectUrl: redirectUrl,
      tenantId: tenantId.isEmpty ? null : tenantId,
    );
  }
}
