import 'dart:convert';

import 'package:http/http.dart' as http;

import 'weather_models.dart';
import 'weather_runtime_config.dart';
import 'weather_service.dart';

class WeatherProviderException implements Exception {
  const WeatherProviderException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'WeatherProviderException($message)';
}

/// AEMET OpenData adapter.
///
/// Credentials are injected at runtime and are never persisted by this class.
/// AEMET returns a metadata envelope first; the actual forecast is then
/// obtained from the URL contained in `datos`.
class AemetWeatherService implements WeatherService {
  AemetWeatherService({
    required WeatherRuntimeConfig config,
    http.Client? client,
    this.baseUri = 'https://opendata.aemet.es/opendata/api',
  })  : _config = config,
        _client = client ?? http.Client();

  final WeatherRuntimeConfig _config;
  final http.Client _client;
  final String baseUri;

  @override
  Future<WeatherForecast> dailyMunicipalityForecast(
    String municipalityCode,
  ) async {
    final code = municipalityCode.trim();
    if (!RegExp(r'^\d{5}$').hasMatch(code)) {
      throw const WeatherProviderException('Código de municipio inválido.');
    }

    try {
      _config.validate(DateTime.now().toUtc());
    } on WeatherConfigurationException catch (error) {
      throw WeatherProviderException(error.message);
    }

    final envelope = await _getJson(
      '$baseUri/prediccion/especifica/municipio/diaria/$code',
    );
    final dataUrl = envelope['datos'];
    if (dataUrl is! String || dataUrl.isEmpty) {
      throw const WeatherProviderException(
        'AEMET no devolvió una URL de datos.',
      );
    }

    final payload = await _getJson(dataUrl, includeApiKey: false);
    return _parseForecast(payload);
  }

  Future<Map<String, dynamic>> _getJson(
    String url, {
    bool includeApiKey = true,
  }) async {
    final response = await _client
        .get(
          Uri.parse(url),
          headers: includeApiKey ? {'api_key': _config.apiKey} : null,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WeatherProviderException(
        'Proveedor meteorológico no disponible.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const WeatherProviderException(
        'Respuesta meteorológica inválida.',
      );
    }
    return decoded;
  }

  WeatherForecast _parseForecast(Map<String, dynamic> payload) {
    final municipio = payload['prediccion'];
    final days = municipio is Map<String, dynamic> ? municipio['dia'] : null;
    if (days is! List) {
      throw const WeatherProviderException(
        'Formato de predicción AEMET no reconocido.',
      );
    }

    final parsed = <WeatherDay>[];
    for (final item in days) {
      if (item is! Map<String, dynamic>) continue;
      final date = DateTime.tryParse('${item['fecha'] ?? ''}');
      if (date == null) continue;

      parsed.add(
        WeatherDay(
          date: date,
          condition: _condition(item['estadoCielo']),
          minTemperatureC: _number(item['temperatura'], 'minima'),
          maxTemperatureC: _number(item['temperatura'], 'maxima'),
          precipitationProbabilityPercent:
              _firstInt(item['probPrecipitacion']),
          precipitationMm: _firstNumber(item['precipitacion']),
          windSpeedKmh: _windSpeed(item['viento']),
          windDirection: _windDirection(item['viento']),
        ),
      );
    }

    return WeatherForecast(
      days: List.unmodifiable(parsed),
      source: 'AEMET OpenData',
      fetchedAt: DateTime.now().toUtc(),
    );
  }

  double? _number(dynamic parent, String key) {
    if (parent is! Map) return null;
    return double.tryParse('${parent[key] ?? ''}'.replaceAll(',', '.'));
  }

  int? _firstInt(dynamic value) => _firstNumber(value)?.round();

  double? _firstNumber(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map) {
        for (final key in const ['value', 'valor']) {
          final parsed = double.tryParse(
            '${first[key] ?? ''}'.replaceAll(',', '.'),
          );
          if (parsed != null) return parsed;
        }
      }
      return _firstNumber(first);
    }
    return null;
  }

  double? _windSpeed(dynamic value) {
    if (value is! List || value.isEmpty || value.first is! Map) return null;
    final first = value.first as Map;
    return _firstNumber(first['velocidad']);
  }

  String? _windDirection(dynamic value) {
    if (value is! List || value.isEmpty || value.first is! Map) return null;
    final first = value.first as Map;
    final direction = first['direccion']?.toString();
    return direction?.trim().isEmpty == true ? null : direction;
  }

  WeatherCondition _condition(dynamic value) {
    final first = value is List && value.isNotEmpty && value.first is Map
        ? value.first as Map
        : null;
    final text = '${first?['descripcion'] ?? ''}';
    final normalized = text.toLowerCase();

    if (normalized.contains('torment')) return WeatherCondition.storm;
    if (normalized.contains('nieve')) return WeatherCondition.snow;
    if (normalized.contains('lluv') || normalized.contains('precipit')) {
      return WeatherCondition.rain;
    }
    if (normalized.contains('niebla')) return WeatherCondition.fog;
    if (normalized.contains('nub') && normalized.contains('poco')) {
      return WeatherCondition.partlyCloudy;
    }
    if (normalized.contains('nub')) return WeatherCondition.cloudy;
    if (normalized.contains('despej')) return WeatherCondition.clear;
    return WeatherCondition.unknown;
  }
}
