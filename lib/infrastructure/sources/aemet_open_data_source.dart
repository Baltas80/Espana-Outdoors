import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/contracts/source_gateway.dart';

/// Adapter for AEMET OpenData REST. Credentials are supplied at runtime;
/// never commit an API key to the repository.
class AemetOpenDataSource implements SourceGateway {
  AemetOpenDataSource({required String apiKey, http.Client? client})
      : _apiKey = apiKey,
        _client = client ?? http.Client();

  static const _base = 'https://opendata.aemet.es/opendata/api/';
  final String _apiKey;
  final http.Client _client;

  @override
  Future<SourceSnapshot> health(String sourceId) async {
    try {
      await fetch(sourceId);
      return SourceSnapshot(
        sourceId: sourceId,
        kind: SourceKind.official,
        status: SourceStatus.healthy,
        observedAt: DateTime.now().toUtc(),
        licenseUrl: 'https://www.aemet.es/es/nota_legal',
        attribution: 'AEMET OpenData',
      );
    } catch (_) {
      return SourceSnapshot(
        sourceId: sourceId,
        kind: SourceKind.official,
        status: SourceStatus.unavailable,
        observedAt: DateTime.now().toUtc(),
        licenseUrl: 'https://www.aemet.es/es/nota_legal',
        attribution: 'AEMET OpenData',
      );
    }
  }

  @override
  Future<List<Map<String, Object?>>> fetch(
    String sourceId, {
    Map<String, Object?> parameters = const {},
  }) async {
    final endpoint = parameters['endpoint'] as String? ?? sourceId;
    final uri = Uri.parse('$_base$endpoint').replace(
      queryParameters: {
        'api_key': _apiKey,
        for (final entry in parameters.entries)
          if (entry.key != 'endpoint') entry.key: '${entry.value}',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('AEMET OpenData failed: HTTP ${response.statusCode}');
    }
    final envelope = jsonDecode(response.body);
    if (envelope is! Map<String, dynamic>) {
      throw FormatException('Invalid AEMET response envelope.');
    }

    final dataUrl = envelope['datos'];
    if (dataUrl is! String || dataUrl.isEmpty) {
      throw FormatException('AEMET response does not contain datos URL.');
    }

    final dataResponse = await _client.get(Uri.parse(dataUrl));
    if (dataResponse.statusCode < 200 || dataResponse.statusCode >= 300) {
      throw StateError('AEMET data request failed: HTTP ${dataResponse.statusCode}');
    }
    final data = jsonDecode(dataResponse.body);
    if (data is! List) return const [];

    return [
      for (final item in data)
        if (item is Map) Map<String, Object?>.from(item),
    ];
  }
}
