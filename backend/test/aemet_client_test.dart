import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../lib/aemet_client.dart';

void main() {
  test('AEMET client follows datos URL and caches the result', () async {
    final client = _QueueClient([
      http.Response(
        jsonEncode({
          'estado': 200,
          'datos': 'https://aemet.test/data',
        }),
        200,
      ),
      http.Response(
        jsonEncode({
          'prediccion': {
            'dia': [
              {
                'fecha': '2026-09-23',
                'temperatura': {'minima': 10, 'maxima': 22},
              },
            ],
          },
        }),
        200,
      ),
    ]);
    final service = AemetGatewayClient(
      apiKey: 'runtime-test-key',
      baseUri: 'https://aemet.test/api',
      client: client,
    );

    final first = await service.municipalityDaily('30001');
    final second = await service.municipalityDaily('30001');

    expect(first['prediccion'], isNotNull);
    expect(second['prediccion'], isNotNull);
    expect(client.requestCount, 2);
  });

  test('returns stale cached data when AEMET is unavailable', () async {
    final client = _QueueClient([
      http.Response(
        jsonEncode({
          'estado': 200,
          'datos': 'https://aemet.test/data',
        }),
        200,
      ),
      http.Response(
        jsonEncode({
          'prediccion': {
            'dia': [
              {
                'fecha': '2026-09-23',
                'temperatura': {'minima': 10, 'maxima': 22},
              },
            ],
          },
        }),
        200,
      ),
      http.Response('temporarily unavailable', 503),
    ]);
    final service = AemetGatewayClient(
      apiKey: 'runtime-test-key',
      baseUri: 'https://aemet.test/api',
      cacheTtl: Duration.zero,
      client: client,
    );

    await service.municipalityDaily('30001');
    final result = await service.municipalityDailyWithMetadata('30001');

    expect(result.stale, isTrue);
    expect(result.payload['prediccion'], isNotNull);
  });

  test('AEMET client rejects malformed municipality codes', () {
    final service = AemetGatewayClient(
      apiKey: 'runtime-test-key',
      client: _QueueClient(const []),
    );
    expect(
      () => service.municipalityDaily('3001'),
      throwsArgumentError,
    );
  });
}

class _QueueClient extends http.BaseClient {
  _QueueClient(this.responses);

  final List<http.Response> responses;
  int requestCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount++;
    if (responses.isEmpty) {
      return http.StreamedResponse(
        Stream<List<int>>.value(const <int>[]),
        500,
      );
    }
    final response = responses.removeAt(0);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
