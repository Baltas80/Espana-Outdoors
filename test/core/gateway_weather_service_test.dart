import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/core/live_data/live_data_models.dart';
import 'package:espana_outdoors/core/weather/gateway_weather_service.dart';

void main() {
  test('normalizes gateway weather and preserves provenance', () async {
    final retrieved = DateTime.utc(2026, 9, 23, 8);
    final service = GatewayWeatherService(
      _FakeGateway(
        data: {
          'prediccion': {
            'dia': [
              {
                'fecha': '2026-09-23',
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
        retrievedAt: retrieved,
      ),
    );

    final forecast = await service.dailyMunicipalityForecast('30008');

    expect(forecast.source, 'AEMET OpenData');
    expect(forecast.fetchedAt, retrieved);
    expect(forecast.days, hasLength(1));
    expect(forecast.days.single.condition.name, 'storm');
    expect(forecast.days.single.maxTemperatureC, 27);
    expect(forecast.days.single.precipitationProbabilityPercent, 80);
    expect(forecast.days.single.precipitationMm, 4.5);
    expect(forecast.days.single.windSpeedKmh, 25);
    expect(forecast.days.single.windDirection, 'O');
  });

  test('rejects invalid municipality codes before gateway access', () {
    final gateway = _FakeGateway(
      data: const {},
      retrievedAt: DateTime.utc(2026, 9, 23),
    );
    final service = GatewayWeatherService(gateway);

    expect(
      () => service.dailyMunicipalityForecast('Murcia'),
      throwsA(isA<ArgumentError>()),
    );
    expect(gateway.calls, 0);
  });
}

class _FakeGateway implements LiveDataGateway {
  _FakeGateway({
    required this.data,
    required this.retrievedAt,
  });

  final Object data;
  final DateTime retrievedAt;
  int calls = 0;

  @override
  Future<LiveDataEnvelope<T>> get<T>(
    String resource,
    Map<String, String> query,
  ) async {
    calls++;
    return LiveDataEnvelope<T>(
      data: data as T,
      provenance: LiveDataProvenance(
        sourceId: 'aemet-opendata',
        sourceName: 'AEMET OpenData',
        retrievedAt: retrievedAt,
        freshness: FreshnessState.fresh,
        confidence: 1,
      ),
    );
  }
}
