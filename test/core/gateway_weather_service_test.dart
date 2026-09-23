import 'package:espana_outdoors/core/weather/gateway_weather_service.dart';
import 'package:espana_outdoors/core/weather/weather_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);

  final Future<http.Response> Function(Uri uri) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request.url);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  test('normalizes a gateway forecast without provider credentials', () async {
    Uri? requestedUri;
    final client = _FakeClient((uri) async {
      requestedUri = uri;
      return http.Response(
        '{"source":"AEMET","fetchedAt":"2026-09-23T08:00:00Z",'
        '"days":[{"date":"2026-09-23","condition":"rain",'
        '"minTemperatureC":12,"maxTemperatureC":21,'
        '"precipitationProbabilityPercent":80}]}'
        ,
        200,
        headers: const {'content-type': 'application/json'},
      );
    });

    final service = GatewayWeatherService(
      baseUri: Uri.parse('https://api.example.test/v1'),
      client: client,
    );

    final result = await service.dailyMunicipalityForecast('28079');

    expect(requestedUri.toString(),
        'https://api.example.test/v1/weather/municipality/28079/daily');
    expect(result.source, 'AEMET');
    expect(result.days.single.condition, WeatherCondition.rain);
    expect(result.days.single.precipitationProbabilityPercent, 80);
  });
}
