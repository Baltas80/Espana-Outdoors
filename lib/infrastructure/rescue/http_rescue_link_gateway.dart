import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/rescue/rescue_link_gateway.dart';
import '../../core/domain/outdoor_models.dart';

final class HttpRescueLinkGateway implements RescueLinkGateway {
  HttpRescueLinkGateway({
    required Uri baseUrl,
    required Future<String?> Function() accessToken,
    http.Client? client,
    bool allowHttpForDevelopment = false,
  })  : _baseUrl = _normalize(
          baseUrl,
          allowHttpForDevelopment: allowHttpForDevelopment,
        ),
        _accessToken = accessToken,
        _client = client ?? http.Client();

  final Uri _baseUrl;
  final Future<String?> Function() _accessToken;
  final http.Client _client;

  @override
  Future<RescueLinkRemoteSession> create(
    RescueLinkCreateRequest request,
  ) async {
    final response = await _client.post(
      _uri('/v1/rescue-links'),
      headers: await _headers(),
      body: jsonEncode({
        'latitude': request.position.latitude,
        'longitude': request.position.longitude,
        'accuracyMeters': request.accuracyMeters,
        'type': request.type.name,
        'expiresAt': request.expiresAt.toUtc().toIso8601String(),
      }),
    );
    _ensureSuccess(response);

    final json = _decodeMap(response.body);
    final id = json['id']?.toString() ?? '';
    final token = json['shareToken']?.toString() ?? '';
    final url = Uri.tryParse(json['shareUrl']?.toString() ?? '');
    final expiresAt =
        DateTime.tryParse(json['expiresAt']?.toString() ?? '');

    if (id.isEmpty ||
        token.isEmpty ||
        url == null ||
        !url.hasScheme ||
        expiresAt == null) {
      throw const FormatException('Invalid Rescue Link response.');
    }

    return RescueLinkRemoteSession(
      id: id,
      shareToken: token,
      shareUrl: url,
      expiresAt: expiresAt.toUtc(),
    );
  }

  @override
  Future<void> revoke(String id) async {
    final response = await _client.post(
      _uri('/v1/rescue-links/' + Uri.encodeComponent(id) + '/revoke'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
  }

  @override
  Future<RescueLinkAcceptedSession> accept({
    required String id,
    required String shareToken,
  }) async {
    final response = await _client.post(
      _uri('/v1/rescue-links/' + Uri.encodeComponent(id) + '/accept'),
      headers: await _headers(),
      body: jsonEncode({'shareToken': shareToken}),
    );
    _ensureSuccess(response);

    final json = _decodeMap(response.body);
    final responseId = json['id']?.toString() ?? '';
    final capabilityToken = json['capabilityToken']?.toString() ?? '';
    final expiresAt =
        DateTime.tryParse(json['expiresAt']?.toString() ?? '');
    final locationJson = json['location'];

    if (responseId.isEmpty ||
        capabilityToken.isEmpty ||
        expiresAt == null ||
        locationJson is! Map) {
      throw const FormatException(
        'Invalid Rescue Link acceptance response.',
      );
    }

    final location = _decodeLocation(locationJson);
    return RescueLinkAcceptedSession(
      id: responseId,
      capabilityToken: capabilityToken,
      expiresAt: expiresAt.toUtc(),
      location: location,
    );
  }

  RescueLinkLocation _decodeLocation(Map<dynamic, dynamic> json) {
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    final accuracy = (json['accuracyMeters'] as num?)?.toDouble();
    final capturedAt = DateTime.tryParse(
      json['capturedAt']?.toString() ?? '',
    );
    final type = EmergencyType.values
        .where((item) => item.name == json['type']?.toString())
        .firstOrNull;
    final exact = json['exact'] == true;

    if (latitude == null ||
        longitude == null ||
        accuracy == null ||
        capturedAt == null ||
        type == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        accuracy < 0) {
      throw const FormatException(
        'Invalid Rescue Link location response.',
      );
    }

    return RescueLinkLocation(
      position: GeoPoint(
        latitude: latitude,
        longitude: longitude,
      ),
      accuracyMeters: accuracy,
      capturedAt: capturedAt.toUtc(),
      type: type,
      exact: exact,
    );
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Invalid JSON object.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _accessToken();
    if (token == null || token.isEmpty) {
      throw StateError(
        'Rescue Link requires an authenticated OIDC session.',
      );
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + token,
    };
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Rescue Link request failed: ' + response.statusCode.toString(),
      );
    }
  }

  Uri _uri(String path) => _baseUrl.resolve(path);

  static Uri _normalize(
    Uri value, {
    required bool allowHttpForDevelopment,
  }) {
    final normalized = value.toString().endsWith('/')
        ? value
        : Uri.parse(value.toString() + '/');
    if (normalized.scheme != 'https' &&
        !(allowHttpForDevelopment && normalized.scheme == 'http')) {
      throw ArgumentError.value(
        value,
        'baseUrl',
        'Rescue Link requires HTTPS.',
      );
    }
    return normalized;
  }
}