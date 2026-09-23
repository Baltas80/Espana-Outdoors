import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/contracts/source_gateway.dart';

/// Thin adapter over the official AEMET OpenData REST API.
///
/// The API key is injected at runtime and is never persisted in the repository.
/// AEMET first returns a short-lived `datos` URL; this adapter follows that
/// indirection and exposes normalized JSON records to the application layer.
class AemetSourceGateway implements SourceGateway {
  AemetSourceGateway({
    required String apiKey,
    Uri? baseUri,
    http.Client? client,
  })  : _apiKey = apiKey,
        _baseUri = baseUri ?? Uri.parse('https://opendata.aemet.es/opendata/api/'),
        _client = client ?? http.Client();

  final String _apiKey;
  final Uri _baseUri;
  final http.Client _client;

  @override
  Future<SourceSnapshot> health(String sourceId) async {
    try {
      await _request(sourceId);
      return SourceSnapshot(
        sourceId: sourceId,
        kind: SourceKind.official,
        status: SourceStatus.healthy,
        observedAt: DateTime.now().toUtc(),
        licenseUrl: 'https://opendata.aemet.es/centrodedescargas/info',
        attribution: 'AEMET OpenData',
      );
    } catch (_) {
      return SourceSnapshot(
        sourceId: sourceId,
        kind: SourceKind.official,
        status: SourceStatus.unavailable,
        observedAt: DateTime.now().toUtc(),
        licenseUrl: 'https://opendata.aemet.es/centrodedescargas/info',
        attribution: 'AEMET OpenData',
      );
    }
  }

  @override
  Future<List<Map<String, Object?>>> fetch(
    String sourceId, {
    Map<String, Object?> parameters = const {},
  }) async {
    final response = await _request(sourceId, parameters: parameters);
    final decoded = jsonDecode(response);
    if (decoded is List) {
      return decoded.whereType<Map>().map(_asObjectMap).toList(growable: false);
    }
    if (decoded is Map<String, dynamic>) {
      return [_asObjectMap(decoded)];
    }
    throw const FormatException('Unexpected AEMET payload.');
  }

  Future<String> _request(
    String sourceId, {
    Map<String, Object?> parameters = const {},
  }) async {
    final endpoint = _endpoint(sourceId);
    final query = <String, String>{'api_key': _apiKey};
    for (final entry in parameters.entries) {
      if (entry.value != null) query[entry.key] = '${entry.value}';
    }

    final first = await _client.get(
      _baseUri.resolve(endpoint).replace(queryParameters: query),
      headers: const {'cache-control': 'no-cache'},
    );
    _ensureSuccess(first.statusCode, 'AEMET metadata request');

    final envelope = jsonDecode(first.body);
    if (envelope is! Map<String, dynamic>) {
      throw const FormatException('Invalid AEMET response envelope.');
    }

    final datos = envelope['datos'];
    if (datos is! String || datos.isEmpty) {
      throw const FormatException('AEMET response has no datos URL.');
    }

    final dataResponse = await _client.get(Uri.parse(datos));
    _ensureSuccess(dataResponse.statusCode, 'AEMET data request');
    return dataResponse.body;
  }

  String _endpoint(String sourceId) {
    switch (sourceId) {
      case 'aemet.alerts.now':
        return 'avisos/ahora/';
      default:
        if (sourceId.startsWith('aemet:')) return sourceId.substring(6);
        throw ArgumentError.value(sourceId, 'sourceId', 'Unsupported AEMET source.');
    }
  }

  static Map<String, Object?> _asObjectMap(Map value) =>
      value.map((key, value) => MapEntry('$key', value));

  static void _ensureSuccess(int statusCode, String operation) {
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('$operation failed: HTTP $statusCode');
    }
  }
}
