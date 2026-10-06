import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'oidc_config.dart';

final class OidcService {
  OidcService({
    required OidcConfig config,
    FlutterAppAuth? appAuth,
    FlutterSecureStorage? storage,
  })  : _config = config,
        _appAuth = appAuth ?? FlutterAppAuth(),
        _storage = storage ?? FlutterSecureStorage();

  final OidcConfig _config;
  final FlutterAppAuth _appAuth;
  final FlutterSecureStorage _storage;

  bool _loaded = false;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _accessTokenExpiration;

  bool get isConfigured => _config.isConfigured;

  Future<AuthorizationTokenResponse> signIn() async {
    if (!_config.isConfigured) {
      throw StateError('OIDC configuration is incomplete');
    }

    final response = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _config.clientId,
        _config.redirectUrl,
        issuer: _config.issuer.toString(),
        scopes: const ['openid', 'profile', 'email', 'offline_access'],
      ),
    );
    await _storeTokenResponse(response);
    return response;
  }

  Future<TokenResponse> refresh(String refreshToken) async {
    if (refreshToken.isEmpty) {
      throw ArgumentError.value(refreshToken, 'refreshToken');
    }
    if (!_config.isConfigured) {
      throw StateError('OIDC configuration is incomplete');
    }

    final response = await _appAuth.token(
      TokenRequest(
        _config.clientId,
        _config.redirectUrl,
        issuer: _config.issuer.toString(),
        refreshToken: refreshToken,
        scopes: const ['openid', 'profile', 'email', 'offline_access'],
      ),
    );
    await _storeTokenResponse(
      response,
      fallbackRefreshToken: refreshToken,
    );
    return response;
  }

  Future<bool> isSignedIn() async {
    try {
      return await accessToken() != null;
    } on Object {
      return false;
    }
  }

  Future<String?> accessToken() async {
    if (!_config.isConfigured) {
      return null;
    }

    await _ensureLoaded();

    final accessToken = _accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final expiration = _accessTokenExpiration;
    if (expiration == null ||
        expiration.isAfter(
          DateTime.now().toUtc().add(const Duration(seconds: 30)),
        )) {
      return accessToken;
    }

    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _clearSession();
      return null;
    }

    final refreshed = await refresh(refreshToken);
    return refreshed.accessToken ?? _accessToken;
  }

  Future<void> signOut() => _clearSession();

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }
    _loaded = true;

    _accessToken = await _storage.read(key: _storageKey('access_token'));
    _refreshToken = await _storage.read(key: _storageKey('refresh_token'));
    final expiration = await _storage.read(
      key: _storageKey('access_token_expiration'),
    );
    _accessTokenExpiration =
        expiration == null ? null : DateTime.tryParse(expiration)?.toUtc();
  }

  Future<void> _storeTokenResponse(
    TokenResponse response, {
    String? fallbackRefreshToken,
  }) async {
    final accessToken = response.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('OIDC provider returned no access token.');
    }

    _accessToken = accessToken;
    _refreshToken = response.refreshToken ?? fallbackRefreshToken;
    _accessTokenExpiration =
        response.accessTokenExpirationDateTime?.toUtc();

    await _storage.write(
      key: _storageKey('access_token'),
      value: _accessToken,
    );

    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _storage.delete(key: _storageKey('refresh_token'));
    } else {
      await _storage.write(
        key: _storageKey('refresh_token'),
        value: refreshToken,
      );
    }

    final expiration = _accessTokenExpiration;
    if (expiration == null) {
      await _storage.delete(key: _storageKey('access_token_expiration'));
    } else {
      await _storage.write(
        key: _storageKey('access_token_expiration'),
        value: expiration.toIso8601String(),
      );
    }
  }

  Future<void> _clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _accessTokenExpiration = null;

    await _storage.delete(key: _storageKey('access_token'));
    await _storage.delete(key: _storageKey('refresh_token'));
    await _storage.delete(key: _storageKey('access_token_expiration'));
  }

  String _storageKey(String name) {
    final namespace = sha256.convert(
      utf8.encode('${_config.issuer}|${_config.clientId}'),
    );
    return 'espana_outdoors.oidc.$namespace.$name';
  }
}
