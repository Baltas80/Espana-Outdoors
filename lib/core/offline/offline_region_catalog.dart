import 'dart:convert';

import 'package:http/http.dart' as http;

import 'offline_region.dart';

class OfflineRegionCatalog {
  OfflineRegionCatalog({required Uri endpoint, http.Client? client})
      : _endpoint = _validateEndpoint(endpoint),
        _client = client ?? http.Client();

  final Uri _endpoint;
  final http.Client _client;

  Future<List<OfflineRegion>> fetch() async {
    final response =
        await _client.get(_endpoint).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Offline region catalog failed: HTTP ${response.statusCode}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException(
        'Offline region catalog must be a JSON array.',
      );
    }
    return [
      for (final item in decoded)
        if (item is Map)
          OfflineRegion.fromJson(Map<String, Object?>.from(item)),
    ];
  }

  static Uri? fromEnvironment() {
    const raw = String.fromEnvironment('OFFLINE_CATALOG_URL');
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  static Uri _validateEndpoint(Uri endpoint) {
    if (endpoint.scheme != 'https' || endpoint.host.isEmpty) {
      throw ArgumentError.value(
        endpoint,
        'endpoint',
        'Offline catalog endpoints must use HTTPS.',
      );
    }
    return endpoint;
  }
}
