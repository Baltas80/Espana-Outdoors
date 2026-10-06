import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/core/auth/oidc_config.dart';
import 'package:espana_outdoors/core/auth/oidc_service.dart';

void main() {
  const config = OidcConfig(
    issuer: Uri.parse('https://auth.example.com/realms/espana-outdoor'),
    clientId: 'espana-outdoor-mobile',
    redirectUrl: 'espanaoutdoor://callback',
  );

  String key(String name) {
    final namespace = sha256.convert(
      utf8.encode('${config.issuer}|${config.clientId}'),
    );
    return 'espana_outdoors.oidc.$namespace.$name';
  }

  test('restores an unexpired access token from secure storage', () async {
    FlutterSecureStorage.setMockInitialValues({
      key('access_token'): 'access-token',
      key('access_token_expiration'):
          DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String(),
    });

    final service = OidcService(config: config);

    expect(await service.accessToken(), 'access-token');
    expect(await service.isSignedIn(), isTrue);
  });

  test('signOut clears the local OIDC session', () async {
    FlutterSecureStorage.setMockInitialValues({
      key('access_token'): 'access-token',
      key('access_token_expiration'):
          DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String(),
    });

    final service = OidcService(config: config);
    expect(await service.isSignedIn(), isTrue);

    await service.signOut();

    expect(await service.accessToken(), isNull);
    expect(await service.isSignedIn(), isFalse);
  });
}
