import 'package:flutter/material.dart';
import 'package:openidconnect/openidconnect.dart';

import '../../core/auth/oidc_config.dart';

/// Thin adapter around the mature OpenID Connect implementation.
/// Keycloak remains an infrastructure choice; the app only depends on OIDC.
final class OpenIdConnectAuthService {
  OpenIdConnectAuthService(this.config);

  final OidcConfig config;
  OpenIdConnectClient? _client;

  Future<OpenIdConnectClient> _getClient() async {
    if (!config.isConfigured) {
      throw StateError('OIDC is not configured.');
    }
    return _client ??= await OpenIdConnectClient.create(
      discoveryDocumentUrl:
          '${config.issuer.toString().replaceFirst(RegExp(r'/$'), '')}/.well-known/openid-configuration',
      clientId: config.clientId,
      redirectUrl: config.redirectUrl,
      tenantId: config.tenantId,
      // Compatibility parameter in openidconnect 3.x; token storage uses
      // the package's endorsed secure platform implementation.
      encryptionKey: 'espana-outdoor-oidc-v3',
      scopes: const [
        'openid',
        'profile',
        'email',
        OpenIdConnectClient.OFFLINE_ACCESS_SCOPE,
      ],
    );
  }

  Future<bool> isSignedIn() async => (await _getClient()).isLoggedIn();

  Future<String?> accessToken() async {
    final client = await _getClient();
    if (!await client.verifyToken()) return null;
    return client.identity?.accessToken;
  }

  Future<OpenIdIdentity> signIn(BuildContext context) async {
    final client = await _getClient();
    return client.loginInteractive(
      context: context,
      title: 'Iniciar sesión en España Outdoor',
    );
  }

  Future<void> signOut() async {
    final client = await _getClient();
    await client.logout();
  }

  Future<void> dispose() async {
    _client?.dispose();
    _client = null;
  }
}
