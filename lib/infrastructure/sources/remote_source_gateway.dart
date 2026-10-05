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

    final json = _decodeObject(response.body, 'health');
    _validateHealthEnvelope(json);

    final kind = _parseSourceKind(json['kind']);
    final status = _parseSourceStatus(json['status']);
    final observedAt = _parseDateTime(json['observedAt'], 'observedAt');
    final expiresAt = json['expiresAt'] == null
        ? null
        : _parseDateTime(json['expiresAt'], 'expiresAt');
    final licenseUrl = _parseRequiredHttpsUrl(json['licenseUrl'], 'licenseUrl');
    final attribution = _parseRequiredString(json['attribution'], 'attribution');

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
  Future<SourceDataSnapshot> fetch(
    String sourceId, {
    Map<String, Object?> parameters = const {},
  }) async {
    _validateSourceId(sourceId);

    final query = <String, String>{
      for (final entry in parameters.entries) entry.key: '${entry.value}',
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

    final json = _decodeObject(response.body, 'data');
    _validateDataEnvelope(json);

    final data = json['data'];
    if (data is! List) {
      throw const FormatException(
        'Source gateway data field must be an array.',
      );
    }

    final provenance = json['provenance'] as Map;
    final freshness = json['freshness'] as Map;
    return SourceDataSnapshot(
      data: [for (final item in data) _parseDataRecord(item)],
      provenance: SourceProvenance(
        source: _parseRequiredString(
          provenance['source'],
          'provenance.source',
        ),
        licenseUrl: _parseRequiredHttpsUrl(
          provenance['licenseUrl'],
          'provenance.licenseUrl',
        ),
        observedAt: _parseDateTime(
          provenance['observedAt'],
          'provenance.observedAt',
        ),
      ),
      freshness: SourceFreshness(
        status: _parseRequiredString(
          freshness['status'],
          'freshness.status',
        ),
        fetchedAt: _parseDateTime(
          freshness['fetchedAt'],
          'freshness.fetchedAt',
        ),
      ),
    );
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

  static Map<String, dynamic> _decodeObject(String body, String operation) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (error) {
      throw FormatException(
        'Invalid source gateway $operation response: $error',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(
        'Invalid source gateway $operation response: expected an object.',
      );
    }
    return decoded;
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
    _assertExactKeys(json, required, optional, 'health');

    _parseRequiredString(json['kind'], 'kind');
    _parseRequiredString(json['status'], 'status');
    _parseDateTime(json['observedAt'], 'observedAt');
    _parseRequiredHttpsUrl(json['licenseUrl'], 'licenseUrl');
    _parseRequiredString(json['attribution'], 'attribution');
    if (json['expiresAt'] != null) {
      _parseDateTime(json['expiresAt'], 'expiresAt');
    }
  }

  static void _validateDataEnvelope(Map<String, dynamic> json) {
    const fields = {'data', 'provenance', 'freshness'};
    _assertExactKeys(json, fields, const {}, 'data envelope');

    final provenance = json['provenance'];
    if (provenance is! Map) {
      throw const FormatException(
        'Source gateway provenance must be an object.',
      );
    }
    _assertExactKeys(
      provenance,
      {'source', 'licenseUrl', 'observedAt'},
      const {},
      'provenance',
    );
    _parseRequiredString(provenance['source'], 'provenance.source');
    _parseRequiredHttpsUrl(
      provenance['licenseUrl'],
      'provenance.licenseUrl',
    );
    _parseDateTime(provenance['observedAt'], 'provenance.observedAt');

    final freshness = json['freshness'];
    if (freshness is! Map) {
      throw const FormatException(
        'Source gateway freshness must be an object.',
      );
    }
    _assertExactKeys(
      freshness,
      {'status', 'fetchedAt'},
      const {},
      'freshness',
    );
    final freshnessStatus = _parseRequiredString(
      freshness['status'],
      'freshness.status',
    );
    if (!const {'current', 'aging', 'stale'}.contains(freshnessStatus)) {
      throw const FormatException(
        'Source gateway freshness status is invalid.',
      );
    }
    _parseDateTime(freshness['fetchedAt'], 'freshness.fetchedAt');
  }

  static Map<String, Object?> _parseDataRecord(Object? value) {
    if (value is! Map) {
      throw const FormatException(
        'Source gateway data records must be objects.',
      );
    }
    return Map<String, Object?>.from(value);
  }

  static void _assertExactKeys(
    Map<dynamic, dynamic> value,
    Set<String> required,
    Set<String> optional,
    String scope,
  ) {
    final keys = value.keys.map((key) => '$key').toSet();
    final allowed = {...required, ...optional};
    final unexpected = keys.where((key) => !allowed.contains(key));
    if (unexpected.isNotEmpty || !keys.containsAll(required)) {
      throw FormatException(
        'Source gateway $scope schema is invalid.',
      );
    }
  }

  static String _parseRequiredString(Object? value, String field) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Source gateway field $field must be a non-empty string.',
      );
    }
    return value;
  }

  static DateTime _parseDateTime(Object? value, String field) {
    if (value is! String) {
      throw FormatException(
        'Source gateway field $field must be a date-time string.',
      );
    }
    final parsed = DateTime.tryParse(value)?.toUtc();
    if (parsed == null) {
      throw FormatException(
        'Source gateway field $field has an invalid date-time.',
      );
    }
    return parsed;
  }

  static String _parseRequiredHttpsUrl(Object? value, String field) {
    final text = _parseRequiredString(value, field);
    final uri = Uri.tryParse(text);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException(
        'Source gateway field $field must use HTTPS.',
      );
    }
    return text;
  }

  static SourceKind _parseSourceKind(Object? value) {
    final text = _parseRequiredString(value, 'kind');
    for (final kind in SourceKind.values) {
      if (kind.name == text) return kind;
    }
    throw FormatException('Unknown source kind: $text');
  }

  static SourceStatus _parseSourceStatus(Object? value) {
    final text = _parseRequiredString(value, 'status');
    for (final status in SourceStatus.values) {
      if (status.name == text) return status;
    }
    throw FormatException('Unknown source status: $text');
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
