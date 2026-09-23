import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/contracts/source_gateway.dart';
import '../../core/source_gateway/source_gateway_config.dart';

typedef AccessTokenProvider = Future<String?> Function();

/// Client for the first-party Source Gateway. Provider credentials remain on
/// the server; the mobile client receives normalized, attributed records.
final class RemoteSourceGateway implements SourceGateway {
  RemoteSourceGateway({
    required this.baseUri,
    http.Client? client,
    this.accessTokenProvider,
  }) : _client = client ?? http.Client() {
    if (baseUri.scheme != 'https' || baseUri.host.isEmpty) {
      throw ArgumentError.value(
        baseUri,
        'baseUri',
        'Production Source Gateway endpoints must use HTTPS.',
      );
    }
  }

  final Uri baseUri;
  final http.Client _client;
  final AccessTokenProvider? accessTokenProvider;
  final AccessTokenProvider? accessTokenProvider;

  @override
  Future<SourceSnapshot> health(String sourceId) async {
    _validateSourceId(sourceId);

    final response = await _client.get(
      _uri('/v1/sources/$sourceId/health'),
      headers: await _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Source gateway health failed: HTTP ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid source gateway health response.');
    }

    final observedAt = DateTime.tryParse('${json['observedAt']}')?.toUtc();
    if (observedAt == null) {
      throw const FormatException(
        'Source gateway health response has invalid observedAt.',
      );
    }

    final expiresAt = json['expiresAt'] == null
        ? null
        : DateTime.tryParse('${json['expiresAt']}')?.toUtc();
    if (json['expiresAt'] != null && expiresAt == null) {
      throw const FormatException(
        'Source gateway health response has invalid expiresAt.',
      );
    }

    return SourceSnapshot(
      sourceId: sourceId,
      kind: SourceKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => SourceKind.official,
      ),
      status: SourceStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => SourceStatus.unavailable,
      ),
      observedAt: observedAt,
      expiresAt: expiresAt,
      licenseUrl: json['licenseUrl'] as String?,
      attribution: json['attribution'] as String?,
    );
  }

  @override
  Future<List<Map<String, Object?>>> fetch(
    String sourceId, {
    Map<String, Object?> parameters = const {},
  }) async {
    _validateSourceId(sourceId);

    final query = <String, String>{
      for (final entry in parameters.entries)
        entry.key: '${entry.value}',
    };
    final response = await _client.get(
      _uri('/v1/sources/$sourceId', queryParameters: query),
      headers: await _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Source gateway fetch failed: HTTP ${response.statusCode}',
      );
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

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    final provider = accessTokenProvider;
    if (provider != null) {
      final token = (await provider())?.trim();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Accept': 'application/json'};
    final provider = accessTokenProvider;
    if (provider == null) return headers;
    final token = (await provider())?.trim();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static RemoteSourceGateway fromEnvironment({
    AccessTokenProvider? accessTokenProvider,
    http.Client? client,
  }) {
    final config = SourceGatewayConfig.fromEnvironment();
    config.validate();
    return RemoteSourceGateway(
      baseUri: config.baseUri,
      accessTokenProvider: accessTokenProvider,
      client: client,
    );
  }

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final normalized = baseUri.toString().replaceFirst(RegExp(r'/$'), '');
    return Uri.parse(Uri.encodeFull('$normalized$path')).replace(
      queryParameters: queryParameters,
    );
  }

  static void _validateSourceId(String sourceId) {
    final normalized = sourceId.trim();
    if (normalized.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9._:-]+$').hasMatch(normalized)) {
      throw ArgumentError.value(
        sourceId,
        'sourceId',
        'Invalid source identifier.',
      );
    }
  }

  void close() => _client.close();
}
