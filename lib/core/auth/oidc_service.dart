import 'package:flutter_appauth/flutter_appauth.dart';

import 'oidc_config.dart';

final class OidcService {
  OidcService({
    required OidcConfig config,
    FlutterAppAuth? appAuth,
  })  : _config = config,
        _appAuth = appAuth ?? const FlutterAppAuth();

  final OidcConfig _config;
  final FlutterAppAuth _appAuth;

  Future<AuthorizationTokenResponse> signIn() {
    if (!_config.isConfigured) {
      throw StateError('OIDC configuration is incomplete');
    }

    return _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _config.clientId,
        _config.redirectUrl,
        issuer: _config.issuer.toString(),
        scopes: const ['openid', 'profile', 'email', 'offline_access'],
        preferEphemeralSession: false,
      ),
    );
  }

  Future<TokenResponse> refresh(String refreshToken) {
    if (refreshToken.isEmpty) {
      throw ArgumentError.value(refreshToken, 'refreshToken');
    }
    return _appAuth.token(
      TokenRequest(
        _config.clientId,
        _config.redirectUrl,
        issuer: _config.issuer.toString(),
        refreshToken: refreshToken,
        scopes: const ['openid', 'profile', 'email', 'offline_access'],
      ),
    );
  }
}
