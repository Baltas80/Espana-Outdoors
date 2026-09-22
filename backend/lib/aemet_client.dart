import 'dart:convert';

import 'package:http/http.dart' as http;

class AemetGatewayClient {
  AemetGatewayClient({
    required this.apiKey,
    http.Client? client,
    this.baseUri = 'https://opendata.aemet.es/opendata/api',
    this.cacheTtl = const Duration(minutes: 10),
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String baseUri;
  final Duration cacheTtl;
  final http.Client _client;
  final Map<String, _CachedResponse> _cache = {};

  Future<Map<String, dynamic>> municipalityDaily(String code) async {
    if (!RegExp(r'^\d{5}$').hasMatch(code)) {
      throw ArgumentError.value(
        code,
        'code',
        'Código INE de municipio inválido.',
      );
    }

    final cached = _cache[code];
    if (cached != null &&
        DateTime.now().toUtc().difference(cached.retrievedAt) <= cacheTtl) {
      return cached.payload;
    }

    final envelope = await _getJson(
      Uri.parse(
        '\$baseUri/prediccion/especifica/municipio/diaria/\$code',
      ),
      includeApiKey: true,
    );
    final dataUrl = envelope['datos'];
    if (dataUrl is! String || dataUrl.isEmpty) {
      throw StateError('AEMET no devolvió una URL de datos.');
    }

    final payload = await _getJson(
      Uri.parse(dataUrl),
      includeApiKey: false,
    );
    _cache[code] = _CachedResponse(
      payload: payload,
      retrievedAt: DateTime.now().toUtc(),
    );
    return payload;
  }

  Future<Map<String, dynamic>> _getJson(
    Uri uri, {
    required bool includeApiKey,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _client
            .get(
              uri,
              headers: includeApiKey
                  ? {'api_key': apiKey}
                  : const <String, String>{},
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
          throw StateError('Respuesta JSON no objeto.');
        }

        if (response.statusCode != 429 && response.statusCode < 500) {
          throw StateError('AEMET HTTP \${response.statusCode}.');
        }

        lastError = StateError('AEMET HTTP \${response.statusCode}.');
      } catch (error) {
        lastError = error;
      }

      await Future<void>.delayed(
        Duration(milliseconds: 250 * (1 << attempt)),
      );
    }

    throw StateError('AEMET no disponible: \$lastError');
  }
}

class _CachedResponse {
  const _CachedResponse({
    required this.payload,
    required this.retrievedAt,
  });

  final Map<String, dynamic> payload;
  final DateTime retrievedAt;
}
