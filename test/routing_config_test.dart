import 'package:espana_outdoors/core/routing/routing_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routing config is disabled when endpoint is not injected', () {
    const config = RoutingConfig(baseUri: null);
    expect(config.isConfigured, isFalse);
  });

  test('routing config accepts a valid endpoint', () {
    final config = RoutingConfig(
      baseUri: Uri.parse('https://routing.example.com/'),
    );
    expect(config.isConfigured, isTrue);
    expect(config.baseUri!.host, 'routing.example.com');
  });
}

  test('routing config rejects HTTP endpoints by default', () {
    const config = RoutingConfig(
      baseUri: Uri.parse('http://routing.example.com/'),
    );
    expect(config.isConfigured, isFalse);
  });

  test('routing config can explicitly allow HTTP for development', () {
    const config = RoutingConfig(
      baseUri: Uri.parse('http://routing.example.com/'),
      allowHttpForDevelopment: true,
    );
    expect(config.isConfigured, isTrue);
  });
