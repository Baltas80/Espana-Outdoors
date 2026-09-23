import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/core/auth/oidc_config.dart';

void main() {
  test('rejects incomplete OIDC configuration', () {
    final config = OidcConfig(
      issuer: Uri.parse('https://auth.example.com/realms/espana-outdoor'),
      clientId: '',
      redirectUrl: '',
    );

    expect(config.isConfigured, isFalse);
  });

  test('accepts complete OIDC configuration', () {
    final config = OidcConfig(
      issuer: Uri.parse('https://auth.example.com/realms/espana-outdoor'),
      clientId: 'espana-outdoor-mobile',
      redirectUrl: 'espanaoutdoor://callback',
    );

    expect(config.isConfigured, isTrue);
  });
}
