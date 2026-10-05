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

  static const _requestTimeout = Duration(seconds: 20);

  final Uri baseUri;
  final http.Client _client;
  final AccessTokenProvider? accessTokenProvider;

  @override
  Future<SourceSnapshot> health(String sourceId) async {
    _validateSourceId(sourceId);

    final response = await _client
        .get(
          _uri('/v1/sources/$sourceId/health'),
          headers: await _headers(),
        )
        .timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Source gateway health failed: HTTP ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid source gateway health response.');
    }

    _validateHealthEnvelope(json);

    final responseSourceId = json['sourceId'];
    if (responseSourceId != null && responseSourceId != sourceId) {
      throw const FormatException('Source gateway returned a mismatched sourceId.');
    }

    final kind = _parseSourceKind(json['kind']);
    final status = _parseSourceStatus(json['status']);

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

    final licenseUrl = _parseLicenseUrl(json['licenseUrl']);
    final attribution = _parseOptionalString(json['attribution'], 'attribution');

    return SourceSnapshot(
      sourceId: sourceId,
      kind: kind,
      status: status,
      observedAt: observedAt,
      expiresAt: expiresAt,
      licenseUrl: licenseUrl,
      attribution: attribution,
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
    final response = await _client
        .get(
          _uri('/v1/sources/$sourceId', queryParameters: query),
          headers: await _headers(),
        )
        .timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Source gateway fetch failed: HTTP ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic> || json['data'] is! List) {
      throw const FormatException(
        'Invalid source gateway data envelope.',
      );
    }
    _validateDataEnvelope(json);
    final data = json['data'] as List;
    return [
      for (final item in data) _parseDataRecord(item),
    ];
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

  static SourceKind _parseSourceKind(Object? value) {
    for (final kind in SourceKind.values) {
      if (kind.name == value) return kind;
    }
    throw FormatException('Unknown source kind: $value');
  }

  static SourceStatus _parseSourceStatus(Object? value) {
    for (final status in SourceStatus.values) {
      if (status.name == value) return status;
    }
    throw FormatException('Unknown source status: $value');
  }

  static String? _parseOptionalString(Object? value, String field) {
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Source gateway field $field must be a non-empty string.');
    }
    return value;
  }

  static String? _parseLicenseUrl(Object? value) {
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Source gateway licenseUrl must be a non-empty string.');
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Source gateway licenseUrl must use HTTPS.');
    }
    return value;
  }

  static Map<String, Object?> _parseDataRecord(Object? value) {
    if (value is! Map) {
      throw const FormatException(
        'Source gateway data record must be an object.',
      );
    }

    final keys = value.keys.map((key) => '$key').toSet();
    const expected = {
      'date',
      'condition',
      'min',
      'max',
      'precipitationProbability',
      'precipitationMm',
      'windSpeed',
      'windDirection',
    };
    if (keys.length != expected.length || !keys.containsAll(expected)) {
      throw const FormatException(
        'Source gateway data record schema is invalid.',
      );
    }

    final date = value['date'];
    if (date is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      throw const FormatException(
        'Source gateway data record date is invalid.',
      );
    }

    final condition = value['condition'];
    if (condition is! String ||
        !const {
          'clear',
          'partlyCloudy',
          'cloudy',
          'rain',
          'storm',
          'snow',
          'fog',
          'unknown',
        }.contains(condition)) {
      throw const FormatException(
        'Source gateway data record condition is invalid.',
      );
    }

    for (final field in const [
      'min',
      'max',
      'precipitationProbability',
      'precipitationMm',
      'windSpeed',
    ]) {
      final fieldValue = value[field];
      if (fieldValue != null && fieldValue is! num) {
        throw FormatException(
          'Source gateway data record field $field must be numeric or null.',
        );
      }
    }

    final windDirection = value['windDirection'];
    if (windDirection != null && windDirection is! String) {
      throw const FormatException(
        'Source gateway data record windDirection is invalid.',
      );
    }

    return Map<String, Object?>.from(value);
  }

  static void _validateHealthEnvelope(Map<String, dynamic> json) {
    const required = {
      'kind',
      'status',
      'observedAt',
      'licenseUrl',
      'attribution',
    };
    const optional = {'expiresAt'};
    final keys = json.keys.toSet();
    final unexpected = keys.where(
      (key) => !required.contains(key) && !optional.contains(key),
    );
    if (unexpected.isNotEmpty || !keys.containsAll(required)) {
      throw const FormatException('Source gateway health schema is invalid.');
    }

    if (json['kind'] is! String ||
        json['status'] is! String ||
        json['observedAt'] is! String) {
      throw const FormatException(
        'Source gateway health schema has invalid field types.',
      );
    }

    if (json['licenseUrl'] is! String ||
        json['attribution'] is! String) {
      throw const FormatException(
        'Source gateway health schema has invalid metadata types.',
      );
    }

    if (json['expiresAt'] != null && json['expiresAt'] is! String) {
      throw const FormatException(
        'Source gateway health schema has invalid expiresAt.',
      );
    }
  }

  static void _validateDataEnvelope(Map<String, dynamic> json) {
    const topLevel = {'data', 'provenance', 'freshness'};
    final unexpected = json.keys.where(
      (key) => !topLevel.contains(key),
    );
    if (unexpected.isNotEmpty) {
      throw FormatException(
        'Source gateway data envelope has unexpected fields: ' +
            unexpected.join(', ') +
            '.',
      );
    }

    final provenance = json['provenance'];
    if (provenance is! Map) {
      throw const FormatException(
        'Source gateway provenance is missing or malformed.',
      );
    }
    final provenanceKeys = provenance.keys.map((key) => '$key').toSet();
    const expectedProvenance = {'source', 'licenseUrl', 'observedAt'};
    if (!provenanceKeys.containsAll(expectedProvenance) ||
        provenanceKeys.length != expectedProvenance.length) {
      throw const FormatException(
        'Source gateway provenance schema is invalid.',
      );
    }

    final freshness = json['freshness'];
    if (freshness is! Map) {
      throw const FormatException(
        'Source gateway freshness is missing or malformed.',
      );
    }
    final freshnessKeys = freshness.keys.map((key) => '$key').toSet();
    const expectedFreshness = {'status', 'fetchedAt'};
    if (!freshnessKeys.containsAll(expectedFreshness) ||
        freshnessKeys.length != expectedFreshness.length) {
      throw const FormatException(
        'Source gateway freshness schema is invalid.',
      );
    }

    final status = freshness['status'];
    if (status is! String ||
        !const {'current', 'aging', 'stale'}.contains(status)) {
      throw const FormatException(
        'Source gateway freshness status is invalid.',
      );
    }
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
).hasMatch(date)) {
      throw const FormatException('Source gateway data record date is invalid.');
    }
    final condition = value['condition'];
    if (condition is! String ||
        !const {
          'clear',
          'partlyCloudy',
          'cloudy',
          'rain',
          'storm',
          'snow',
          'fog',
          'unknown',
        }.contains(condition)) {
      throw const FormatException('Source gateway data record condition is invalid.');
    }
    for (final field in const [
      'min',
      'max',
      'precipitationProbability',
      'precipitationMm',
      'windSpeed',
    ]) {
      final fieldValue = value[field];
      if (fieldValue != null && fieldValue is! num) {
        throw FormatException('Source gateway data record field $field must be numeric or null.');
      }
    }
    final windDirection = value['windDirection'];
    if (windDirection != null && windDirection is! String) {
      throw const FormatException('Source gateway data record windDirection is invalid.');
    }

    return Map<String, Object?>.from(value);
  }

  static void _validateHealthEnvelope(Map<String, dynamic> json) {
    const required = {'kind', 'status', 'observedAt', 'licenseUrl', 'attribution'};
    const optional = {'expiresAt'};
    final keys = json.keys.toSet();
    final unexpected = keys.where((key) => !required.contains(key) && !optional.contains(key));
    if (unexpected.isNotEmpty || !keys.containsAll(required)) {
      throw const FormatException('Source gateway health schema is invalid.');
    }
    if (json['kind'] is! String || json['status'] is! String || json['observedAt'] is! String) {
      throw const FormatException('Source gateway health schema has invalid field types.');
    }
    if (json['licenseUrl'] is! String || json['attribution'] is! String) {
      throw const FormatException('Source gateway health schema has invalid metadata types.');
    }
    if (json['expiresAt'] != null && json['expiresAt'] is! String) {
      throw const FormatException('Source gateway health schema has invalid expiresAt.');
    }
  }

  static void _validateDataEnvelope(Map<String, dynamic> json) {
    const topLevel = {'data', 'provenance', 'freshness'};
    final unexpected = json.keys.where((key) => !topLevel.contains(key));
    if (unexpected.isNotEmpty) {
      throw FormatException(
        'Source gateway data envelope has unexpected fields: ' +
            unexpected.join(', ') +
            '.',
      );
    }

    final provenance = json['provenance'];
    if (provenance is! Map) {
      throw const FormatException('Source gateway provenance is missing or malformed.');
    }
    final provenanceKeys = provenance.keys.map((key) => '$key').toSet();
    const expectedProvenance = {'source', 'licenseUrl', 'observedAt'};
    if (!provenanceKeys.containsAll(expectedProvenance) ||
        provenanceKeys.length != expectedProvenance.length) {
      throw const FormatException('Source gateway provenance schema is invalid.');
    }

    final freshness = json['freshness'];
    if (freshness is! Map) {
      throw const FormatException('Source gateway freshness is missing or malformed.');
    }
    final freshnessKeys = freshness.keys.map((key) => '$key').toSet();
    const expectedFreshness = {'status', 'fetchedAt'};
    if (!freshnessKeys.containsAll(expectedFreshness) ||
        freshnessKeys.length != expectedFreshness.length) {
      throw const FormatException('Source gateway freshness schema is invalid.');
    }

    final status = freshness['status'];
    if (status is! String ||
        !const {'current', 'aging', 'stale'}.contains(status)) {
      throw const FormatException('Source gateway freshness status is invalid.');
    }
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
