import '../live_data/live_data_gateway_client.dart';
import 'weather_models.dart';
import 'weather_service.dart';

class GatewayWeatherService implements WeatherService {
  const GatewayWeatherService(this._gateway);

  final HttpLiveDataGateway _gateway;

  @override
  Future<WeatherForecast> dailyMunicipalityForecast(
    String municipalityCode,
  ) async {
    if (!RegExp(r'^\d{5}$').hasMatch(municipalityCode)) {
      throw ArgumentError.value(
        municipalityCode,
        'municipalityCode',
        'Código de municipio inválido.',
      );
    }

    final envelope = await _gateway.get<dynamic>(
      '/v1/weather',
      {'municipalityCode': municipalityCode},
    );

    return _parse(
      envelope.data,
      source: envelope.provenance.sourceName,
      fetchedAt: envelope.provenance.retrievedAt,
      sourceUpdatedAt: envelope.provenance.sourceUpdatedAt,
    );
  }

  WeatherForecast _parse(
    Object? raw, {
    required String source,
    required DateTime fetchedAt,
    DateTime? sourceUpdatedAt,
  }) {
    if (raw is! Map<String, dynamic>) {
      throw const LiveDataGatewayException('Respuesta meteorológica inválida.');
    }

    final prediction = raw['prediccion'];
    final days = prediction is Map<String, dynamic> ? prediction['dia'] : null;
    if (days is! List) {
      throw const LiveDataGatewayException('Formato de predicción no reconocido.');
    }

    final parsedDays = days
        .whereType<Map>()
        .map(_parseDay)
        .whereType<WeatherDay>()
        .toList(growable: false);

    return WeatherForecast(
      days: parsedDays,
      source: source,
      fetchedAt: fetchedAt,
      sourceUpdatedAt: sourceUpdatedAt,
    );
  }

  WeatherDay? _parseDay(Map raw) {
    final date = DateTime.tryParse('${raw['fecha'] ?? ''}');
    if (date == null) return null;

    return WeatherDay(
      date: date,
      condition: _condition(raw['estadoCielo']),
      minTemperatureC: _number(raw['temperatura'], 'minima'),
      maxTemperatureC: _number(raw['temperatura'], 'maxima'),
      precipitationProbabilityPercent: _firstNumber(raw['probPrecipitacion'])?.round(),
      precipitationMm: _firstNumber(raw['precipitacion']),
      windSpeedKmh: _windSpeed(raw['viento']),
      windDirection: _windDirection(raw['viento']),
    );
  }

  double? _number(Object? value, String key) {
    if (value is! Map) return null;
    return double.tryParse('${value[key] ?? ''}'.replaceAll(',', '.'));
  }

  double? _firstNumber(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    if (value is List && value.isNotEmpty) return _firstNumber(value.first);
    if (value is Map) {
      for (final key in const ['value', 'valor']) {
        final parsed = double.tryParse('${value[key] ?? ''}'.replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  double? _windSpeed(Object? value) {
    if (value is! List || value.isEmpty || value.first is! Map) return null;
    return _firstNumber((value.first as Map)['velocidad']);
  }

  String? _windDirection(Object? value) {
    if (value is! List || value.isEmpty || value.first is! Map) return null;
    final direction = '${(value.first as Map)['direccion'] ?? ''}'.trim();
    return direction.isEmpty ? null : direction;
  }

  WeatherCondition _condition(Object? value) {
    final first = value is List && value.isNotEmpty && value.first is Map
        ? value.first as Map
        : null;
    final description = '${first?['descripcion'] ?? ''}'.toLowerCase();

    if (description.contains('torment')) return WeatherCondition.storm;
    if (description.contains('nieve')) return WeatherCondition.snow;
    if (description.contains('lluv') || description.contains('precipit')) {
      return WeatherCondition.rain;
    }
    if (description.contains('niebla')) return WeatherCondition.fog;
    if (description.contains('nub') && description.contains('poco')) {
      return WeatherCondition.partlyCloudy;
    }
    if (description.contains('nub')) return WeatherCondition.cloudy;
    if (description.contains('despej')) return WeatherCondition.clear;
    return WeatherCondition.unknown;
  }
}
