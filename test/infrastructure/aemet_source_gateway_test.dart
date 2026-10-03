import 'dart:async';

import 'package:espana_outdoors/infrastructure/sources/aemet_source_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('bounds a stalled provider request', () async {
    final client = _SlowClient();

    final gateway = AemetSourceGateway(
      apiKey: 'test-key',
      client: client,
      requestTimeout: const Duration(milliseconds: 10),
    );

    expect(
      () => gateway.fetch('aemet.alerts.now'),
      throwsA(isA<TimeoutException>()),
    );
  });
}

final class _SlowClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return http.StreamedResponse(
      Stream.value(<int>[]),
      200,
      request: request,
    );
  }
}
