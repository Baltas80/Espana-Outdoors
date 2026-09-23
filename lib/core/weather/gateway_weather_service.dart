import 'dart:convert';

import 'package:http/http.dart' as http;

import 'weather_models.dart';
import 'weather_service.dart';

/// Production client for the España Outdoor live-data gateway.
///
/// The mobile/web client deliberately does not know provider credentials. The
/// gateway owns provider authentication, rate limits, retries and failover.
class GatewayWeatherService implements WeatherService {
  GatewayWeatherService({
    required Uri baseUri,
    http.Client? client,
  })  : _baseUri = baseUri,
        _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  @override
  Future<WeatherForecast> dailyMunicipalityForecast(
    String municipalityCode,
  ) async {
    final code = municipalityCode.trim();
    if (!RegExp(r'^\d{5}$').hasMatch(code)) {
      throw const FormatException('Código de municipio inválido.');
    }

    final basePath = _baseUri.path.replaceFirst(RegExp(r'/?$'), '');
    final uri = _baseUri.replace(
      path: '$basePath/weather/municipality/$code/daily',
    );

    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Gateway meteorológico no disponible (${response.statusCode}).',
        uri,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Respuesta meteorológica inválida.');
    }

    return _parseForecast(decoded);
  }

  WeatherForecast _parseForecast(Map<String, dynamic> payload) {
    final rawDays = payload['days'];
    if (rawDays is! List) {
      throw const FormatException('Faltan días de predicción.');
    }

    final days = <WeatherDay>[];
    for (final raw in rawDays) {
      if (raw is! Map<String, dynamic>) continue;
      final date = DateTime.tryParse('${raw['date'] ?? ''}');
      if (date == null) continue;

      days.add(
        WeatherDay(
          date: date,
          condition: _condition('${raw['condition'] ?? ''}'),
          minTemperatureC: _double(raw['minTemperatureC']),
          maxTemperatureC: _double(raw['maxTemperatureC']),
          precipitationProbabilityPercent:
              _int(raw['precipitationProbabilityPercent']),
          precipitationMm: _double(raw['precipitationMm']),
          windSpeedKmh: _double(raw['windSpeedKmh']),
          windDirection: raw['windDirection']?.toString(),
        ),
      );
    }

    final fetchedAt = DateTime.tryParse('${payload['fetchedAt'] ?? ''}') ??
        DateTime.now().toUtc();
    final sourceUpdatedAt = DateTime.tryParse(
      '${payload['sourceUpdatedAt'] ?? ''}',
    );

    return WeatherForecast(
      days: List.unmodifiable(days),
      source: '${payload['source'] ?? 'España Outdoor gateway'}',
      fetchedAt: fetchedAt,
      sourceUpdatedAt: sourceUpdatedAt,
    );
  }

  double? _double(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse('${value ?? ''}'.replaceAll(',', '.'));

  int? _int(dynamic value) => value is num
      ? value.round()
      : int.tryParse('${value ?? ''}');

  WeatherCondition _condition(String value) {
    switch (value.trim().toLowerCase()) {
      case 'clear':
        return WeatherCondition.clear;
      case 'partlycloudy':
        return WeatherCondition.partlyCloudy;
      case 'cloudy':
        return WeatherCondition.cloudy;
      case 'rain':
        return WeatherCondition.rain;
      case 'storm':
        return WeatherCondition.storm;
      case 'snow':
        return WeatherCondition.snow;
      case 'fog':
        return WeatherCondition.fog;
      default:
        return WeatherCondition.unknown;
    }
  }
}
