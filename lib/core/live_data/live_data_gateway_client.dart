import 'dart:convert';

import 'package:http/http.dart' as http;

import 'live_data_models.dart';

class LiveDataGatewayException implements Exception {
  const LiveDataGatewayException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'LiveDataGatewayException($message)';
}

class HttpLiveDataGateway implements LiveDataGateway {
  HttpLiveDataGateway({
    required Uri baseUri,
    required String bearerToken,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  })  : _baseUri = baseUri,
        _bearerToken = bearerToken,
        _client = client ?? http.Client();

  final Uri _baseUri;
  final String _bearerToken;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<LiveDataEnvelope<T>> get<T>(
    String resource,
    Map<String, String> query,
  ) async {
    final uri = _baseUri.resolve(resource).replace(queryParameters: query);
    final response = await _client.get(
      uri,
      headers: {
        'authorization': 'Bearer $_bearerToken',
        'accept': 'application/json',
      },
    ).timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LiveDataGatewayException(
        'Live Data Gateway no disponible.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const LiveDataGatewayException('Respuesta del gateway inválida.');
    }
    final data = decoded['data'];
    final rawProvenance = decoded['provenance'];
    if (rawProvenance is! Map<String, dynamic>) {
      throw const LiveDataGatewayException('Falta la proveniencia de los datos.');
    }

    return LiveDataEnvelope<T>(
      data: data as T,
      provenance: _parseProvenance(rawProvenance),
    );
  }

  LiveDataProvenance _parseProvenance(Map<String, dynamic> json) {
    final confidence = (json['confidence'] as num?)?.toDouble() ?? 0;
    if (confidence < 0 || confidence > 1) {
      throw const LiveDataGatewayException('Confianza de datos inválida.');
    }

    return LiveDataProvenance(
      sourceId: '${json['sourceId'] ?? ''}',
      sourceName: '${json['sourceName'] ?? ''}',
      retrievedAt: DateTime.parse('${json['retrievedAt']}'),
      freshness: switch ('${json['freshnessState'] ?? 'unknown'}') {
        'fresh' => FreshnessState.fresh,
        'stale' => FreshnessState.stale,
        'unavailable' => FreshnessState.unavailable,
        _ => FreshnessState.unknown,
      },
      confidence: confidence,
      sourceUrl: json['sourceUrl']?.toString(),
      license: json['license']?.toString(),
      attribution: json['attribution']?.toString(),
      sourceUpdatedAt: _date(json['sourceUpdatedAt']),
      validFrom: _date(json['validFrom']),
      validUntil: _date(json['validUntil']),
      adapterVersion: json['adapterVersion']?.toString(),
    );
  }

  DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse('$value');
}
