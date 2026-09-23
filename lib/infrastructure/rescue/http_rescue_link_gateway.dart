import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/rescue/rescue_link_gateway.dart';

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
      _uri(
        '/v1/rescue-links/' + Uri.encodeComponent(id) + '/revoke',
      ),
      headers: await _headers(),
    );
    _ensureSuccess(response);
  }

  @override
  Future<RescueLinkRemoteSession> accept({
    required String id,
    required String role,
  }) async {
    final response = await _client.post(
      _uri(
        '/v1/rescue-links/' + Uri.encodeComponent(id) + '/accept',
      ),
      headers: await _headers(),
      body: jsonEncode({'role': role}),
    );
    _ensureSuccess(response);

    final json = _decodeMap(response.body);
    final token = json['shareToken']?.toString() ?? '';
    final url = Uri.tryParse(json['shareUrl']?.toString() ?? '');
    final expiresAt =
        DateTime.tryParse(json['expiresAt']?.toString() ?? '');

    if (token.isEmpty ||
        url == null ||
        !url.hasScheme ||
        expiresAt == null) {
      throw const FormatException(
        'Invalid Rescue Link acceptance response.',
      );
    }

    return RescueLinkRemoteSession(
      id: id,
      shareToken: token,
      shareUrl: url,
      expiresAt: expiresAt.toUtc(),
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
        'Rescue Link request failed: ' +
            response.statusCode.toString(),
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
