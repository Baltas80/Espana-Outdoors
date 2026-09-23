import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../lib/aemet_client.dart';
import '../lib/alert_catalog.dart';

Future<void> main() async {
  final aemetKey = Platform.environment['AEMET_API_KEY'];
  final bearerToken = Platform.environment['GATEWAY_BEARER_TOKEN']?.trim();
  final catalogPath = Platform.environment['OFFLINE_CATALOG_FILE']?.trim();
  final alertsPath = Platform.environment['OFFICIAL_ALERTS_FILE']?.trim();
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;

  if (aemetKey == null || aemetKey.isEmpty) {
    stderr.writeln('AEMET_API_KEY is required.');
    exitCode = 64;
    return;
  }

  final aemet = AemetGatewayClient(apiKey: aemetKey);
  final rate = <String, _RateWindow>{};
  final router = Router();

  router.get(
    '/health',
    (Request request) =>
        Response.ok(jsonEncode({'status': 'ok'}), headers: _jsonHeaders()),
  );

  router.get('/v1/weather', (Request request) async {
    if (!_authorized(request, bearerToken)) {
      return _unauthorized();
    }
    if (_rateLimited(request, rate)) {
      return _rateLimitedResponse();
    }

    final code = request.url.queryParameters['municipalityCode'];
    if (code == null || !RegExp(r'^\d{5}$').hasMatch(code)) {
      return Response(
        400,
        body: jsonEncode({'error': 'invalid municipalityCode'}),
        headers: _jsonHeaders(),
      );
    }

    try {
      final result = await aemet.municipalityDailyWithMetadata(code);
      return Response.ok(
        jsonEncode({
          'data': result.payload,
          'provenance': {
            'sourceId': 'aemet-opendata',
            'sourceName': 'AEMET OpenData',
            'sourceUrl': 'https://opendata.aemet.es/',
            'retrievedAt': result.retrievedAt.toIso8601String(),
            'freshnessState': result.stale ? 'stale' : 'fresh',
            'confidence': 1.0,
            'adapterVersion': '0.1.0',
          },
        }),
        headers: _jsonHeaders(),
      );
    } catch (_) {
      return Response(
        503,
        body: jsonEncode({'error': 'provider_unavailable'}),
        headers: _jsonHeaders(),
      );
    }
  });

  router.get('/v1/alerts', (Request request) async {
    if (_rateLimited(request, rate)) {
      return _rateLimitedResponse();
    }

    final lat = double.tryParse(request.url.queryParameters['lat'] ?? '');
    final lon = double.tryParse(request.url.queryParameters['lon'] ?? '');
    final radiusKm =
        double.tryParse(request.url.queryParameters['radiusKm'] ?? '25') ??
            25;

    if (lat == null ||
        lon == null ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180 ||
        radiusKm < 0 ||
        radiusKm > 500) {
      return Response(
        400,
        body: jsonEncode({'error': 'invalid_alert_query'}),
        headers: _jsonHeaders(),
      );
    }

    if (alertsPath == null || alertsPath.isEmpty) {
      return Response.ok(
        jsonEncode({
          'data': {
            'alerts': const [],
            'generatedAt': DateTime.now().toUtc().toIso8601String(),
          },
          'provenance': {
            'sourceId': 'espana-outdoor-alert-gateway',
            'sourceName': 'España Outdoor Alert Gateway',
            'retrievedAt': DateTime.now().toUtc().toIso8601String(),
            'freshnessState': 'unavailable',
            'confidence': 0.0,
            'adapterVersion': '0.1.0',
          },
        }),
        headers: _jsonHeaders(),
      );
    }

    try {
      final catalog = AlertCatalog(path: alertsPath);
      final now = DateTime.now().toUtc();
      final alerts = await catalog.nearby(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
        now: now,
      );
      return Response.ok(
        jsonEncode({
          'data': {
            'alerts': alerts.map((alert) => alert.toJson()).toList(growable: false),
            'generatedAt': now.toIso8601String(),
          },
          'provenance': {
            'sourceId': 'espana-outdoor-alert-catalog',
            'sourceName': 'España Outdoor Alert Catalog',
            'retrievedAt': now.toIso8601String(),
            'freshnessState': 'fresh',
            'confidence': 1.0,
            'adapterVersion': '0.1.0',
          },
        }),
        headers: _jsonHeaders(),
      );
    } on FormatException catch (_) {
      return Response(
        503,
        body: jsonEncode({'error': 'invalid_alert_catalog'}),
        headers: _jsonHeaders(),
      );
    } catch (_) {
      return Response(
        503,
        body: jsonEncode({'error': 'alert_catalog_unavailable'}),
        headers: _jsonHeaders(),
      );
    }
  });

  router.get('/v1/maps/catalog', (Request request) async {
    if (_rateLimited(request, rate)) {
      return _rateLimitedResponse();
    }
    if (catalogPath == null || catalogPath.isEmpty) {
      return Response(
        503,
        body: jsonEncode({'error': 'offline_catalog_not_configured'}),
        headers: _jsonHeaders(),
      );
    }

    try {
      final file = File(catalogPath);
      if (!await file.exists()) {
        return Response(
          503,
          body: jsonEncode({'error': 'offline_catalog_unavailable'}),
          headers: _jsonHeaders(),
        );
      }

      final decoded = jsonDecode(await file.readAsString());
      final packages = decoded is List
          ? decoded
          : decoded is Map<String, dynamic>
              ? decoded['packages']
              : null;
      if (packages is! List) {
        return Response(
          500,
          body: jsonEncode({'error': 'invalid_offline_catalog'}),
          headers: _jsonHeaders(),
        );
      }

      final now = DateTime.now().toUtc();
      return Response.ok(
        jsonEncode({
          'data': packages,
          'provenance': {
            'sourceId': 'espana-outdoor-map-catalog',
            'sourceName': 'España Outdoor offline catalog',
            'retrievedAt': now.toIso8601String(),
            'freshnessState': 'fresh',
            'confidence': 1.0,
            'adapterVersion': '0.1.0',
          },
        }),
        headers: _jsonHeaders(),
      );
    } catch (_) {
      return Response(
        500,
        body: jsonEncode({'error': 'invalid_offline_catalog'}),
        headers: _jsonHeaders(),
      );
    }
  });

  final handler =
      const Pipeline().addMiddleware(_safeRequestLogger()).addHandler(router.call);
  await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    port,
    poweredByHeader: null,
  );
}

bool _authorized(Request request, String? expectedToken) {
  if (expectedToken == null || expectedToken.isEmpty) return true;
  return request.headers['authorization'] == 'Bearer $expectedToken';
}

bool _rateLimited(Request request, Map<String, _RateWindow> rate) {
  final connectionInfo = request.context['shelf.io.connection_info'];
  final ip = connectionInfo is HttpConnectionInfo
      ? connectionInfo.remoteAddress.address
      : 'unknown';
  final now = DateTime.now().toUtc();
  final window = rate[ip] ?? _RateWindow(start: now, count: 0);
  if (now.difference(window.start) >= const Duration(minutes: 1)) {
    rate[ip] = _RateWindow(start: now, count: 1);
    return false;
  }
  if (window.count >= 60) return true;
  rate[ip] = _RateWindow(start: window.start, count: window.count + 1);
  return false;
}

Response _unauthorized() => Response(
      401,
      body: jsonEncode({'error': 'unauthorized'}),
      headers: _jsonHeaders(),
    );

Response _rateLimitedResponse() => Response(
      429,
      body: jsonEncode({'error': 'rate_limited'}),
      headers: {
        ..._jsonHeaders(),
        'retry-after': '60',
      },
    );

Middleware _safeRequestLogger() {
  return (innerHandler) => (request) async {
    stdout.writeln('${request.method} ${request.requestedUri.path}');
    return innerHandler(request);
  };
}

Map<String, String> _jsonHeaders() => const {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
      'x-content-type-options': 'nosniff',
    };

class _RateWindow {
  const _RateWindow({required this.start, required this.count});

  final DateTime start;
  final int count;
}
