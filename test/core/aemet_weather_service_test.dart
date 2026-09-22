import 'dart:convert';

import 'package:espana_outdoors/core/weather/aemet_weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('parses AEMET two-step daily forecast without exposing the API key', () async {
    final client = _QueueClient([
      {
        'estado': 1,
        'datos': 'https://example.test/aemet-data',
      },
      {
        'prediccion': {
          'dia': [
            {
              'fecha': '2026-09-22',
              'estadoCielo': [
                {'descripcion': 'Tormenta con lluvia'},
              ],
              'temperatura': {'minima': 14, 'maxima': 27},
              'probPrecipitacion': [
                {'value': 80},
              ],
              'precipitacion': [
                {'value': 4.5},
              ],
              'viento': [
                {'velocidad': 25, 'direccion': 'O'},
              ],
            },
          ],
        },
      },
    ]);

    final service = AemetWeatherService(
      apiKey: 'test-key-never-persisted',
      client: client,
    );

    final forecast = await service.dailyMunicipalityForecast('28079');

    expect(forecast.source, 'AEMET OpenData');
    expect(forecast.days, hasLength(1));
    expect(forecast.days.single.condition.name, 'storm');
    expect(forecast.days.single.maxTemperatureC, 27);
    expect(forecast.days.single.precipitationProbabilityPercent, 80);
    expect(client.requests.single.headers['api_key'], 'test-key-never-persisted');
    expect(client.requests.last.url.toString(), contains('/28079'));
    expect(client.requests[1].headers.containsKey('api_key'), isFalse);
  });

  test('rejects malformed municipality codes before network access', () async {
    final client = _QueueClient(const []);
    final service = AemetWeatherService(apiKey: 'test', client: client);

    expect(
      () => service.dailyMunicipalityForecast('Madrid'),
      throwsA(isA<WeatherProviderException>()),
    );
    expect(client.requests, isEmpty);
  });
}

class _QueueClient extends http.BaseClient {
  _QueueClient(this._payloads);

  final List<Map<String, dynamic>> _payloads;
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final payload = _payloads.removeAt(0);
    final bytes = utf8.encode(jsonEncode(payload));
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      request: request,
    );
  }
}
