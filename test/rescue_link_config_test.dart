import 'package:espana_outdoors/core/rescue/rescue_link_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts HTTPS Rescue Link endpoint', () {
    final config = RescueLinkConfig(
      baseUrl: Uri.parse('https://rescue.example.com'),
    );

    expect(config.isConfigured, isTrue);
  });

  test('rejects HTTP Rescue Link endpoint by default', () {
    final config = RescueLinkConfig(
      baseUrl: Uri.parse('http://rescue.example.com'),
    );

    expect(config.isConfigured, isFalse);
  });

  test('development HTTP override is debug-only', () {
    final config = RescueLinkConfig(
      baseUrl: Uri.parse('http://localhost:8080'),
      allowHttpForDevelopment: true,
    );

    expect(config.isConfigured, equals(kDebugMode));
  });
}
