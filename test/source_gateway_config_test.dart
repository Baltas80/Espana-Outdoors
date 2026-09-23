import 'package:espana_outdoors/core/source_gateway/source_gateway_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects an empty gateway URL', () {
    final config = SourceGatewayConfig(baseUri: Uri());
    expect(config.isConfigured, isFalse);
    expect(config.validate, throwsA(isA<StateError>()));
  });

  test('accepts an HTTPS gateway URL', () {
    final config = SourceGatewayConfig(
      baseUri: Uri(scheme: 'https', host: 'gateway.example.com'),
    );
    expect(config.isConfigured, isTrue);
    expect(config.validate, returnsNormally);
  });

  test('rejects HTTP gateway endpoints', () {
    final config = SourceGatewayConfig(
      baseUri: Uri(scheme: 'http', host: 'gateway.example.com'),
    );
    expect(config.isConfigured, isFalse);
    expect(config.validate, throwsA(isA<StateError>()));
  });
}
