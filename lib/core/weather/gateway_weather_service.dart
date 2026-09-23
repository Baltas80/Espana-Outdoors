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

    final uri = _baseUri.replace(
      path: '${_baseUri.path.replaceFirst(RegExp(r'/?$'), '')}'
          '/weather/municipality/$code/daily',
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

    return WeatherForecast.fromJson(decoded);
  }
}
