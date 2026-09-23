import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/contracts/source_gateway.dart';

/// Client for the first-party Source Gateway. Provider credentials remain on
/// the server; the mobile/web client receives normalized, attributed records.
final class RemoteSourceGateway implements SourceGateway {
  RemoteSourceGateway({required this.baseUri, http.Client? client})
      : _client = client ?? http.Client();

  final Uri baseUri;
  final http.Client _client;

  @override
  Future<SourceSnapshot> health(String sourceId) async {
    final response = await _client.get(_uri('/v1/sources/$sourceId/health'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Source gateway health failed: HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid source gateway health response.');
    }

    final status = SourceStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => SourceStatus.unavailable,
    );

    return SourceSnapshot(
      sourceId: sourceId,
      kind: SourceKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => SourceKind.official,
      ),
      status: status,
      observedAt: DateTime.tryParse('${json['observedAt']}')?.toUtc() ?? DateTime.now().toUtc(),
      expiresAt: DateTime.tryParse('${json['expiresAt']}')?.toUtc(),
      licenseUrl: json['licenseUrl'] as String?,
      attribution: json['attribution'] as String?,
    );
  }

  @override
  Future<List<Map<String, Object?>>> fetch(
    String sourceId, {
    Map<String, Object?> parameters = const {},
  }) async {
    final query = <String, String>{
      for (final entry in parameters.entries) '${entry.key}': '${entry.value}',
    };
    final response = await _client.get(
      _uri('/v1/sources/$sourceId', queryParameters: query),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Source gateway fetch failed: HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    if (json is List) {
      return [
        for (final item in json)
          if (item is Map) Map<String, Object?>.from(item),
      ];
    }
    if (json is Map && json['data'] is List) {
      final data = json['data'] as List;
      return [
        for (final item in data)
          if (item is Map) Map<String, Object?>.from(item),
      ];
    }
    throw const FormatException('Invalid source gateway data response.');
  }

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final normalized = baseUri.toString().replaceFirst(RegExp(r'/$'), '');
    return Uri.parse('$normalized$path').replace(queryParameters: queryParameters);
  }
}
