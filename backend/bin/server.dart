import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../lib/aemet_client.dart';

Future<void> main() async {
  final aemetKey = Platform.environment['AEMET_API_KEY'];
  final bearerToken = Platform.environment['GATEWAY_BEARER_TOKEN'];
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  if (aemetKey == null || aemetKey.isEmpty || bearerToken == null || bearerToken.isEmpty) {
    stderr.writeln('AEMET_API_KEY and GATEWAY_BEARER_TOKEN are required.');
    exitCode = 64;
    return;
  }

  final aemet = AemetGatewayClient(apiKey: aemetKey);
  final rate = <String, _RateWindow>{};
  final router = Router();

  router.get('/health', (Request request) => Response.ok(jsonEncode({'status': 'ok'}), headers: _jsonHeaders()));
  router.get('/v1/weather', (Request request) async {
    final auth = request.headers['authorization'];
    if (auth != 'Bearer $bearerToken') {
      return Response.forbidden(jsonEncode({'error': 'unauthorized'}), headers: _jsonHeaders());
    }
    final connectionInfo = request.context['shelf.io.connection_info'];
    final ip = connectionInfo is HttpConnectionInfo
        ? connectionInfo.remoteAddress.address
        : 'unknown';
    final now = DateTime.now().toUtc();
    final window = rate[ip] ?? _RateWindow(start: now, count: 0);
    if (now.difference(window.start) >= const Duration(minutes: 1)) {
      rate[ip] = _RateWindow(start: now, count: 1);
    } else if (window.count >= 60) {
      return Response(429, body: jsonEncode({'error': 'rate_limited'}), headers: _jsonHeaders());
    } else {
      rate[ip] = _RateWindow(start: window.start, count: window.count + 1);
    }

    final code = request.url.queryParameters['municipalityCode'];
    if (code == null) {
      return Response(400, body: jsonEncode({'error': 'municipalityCode required'}), headers: _jsonHeaders());
    }
    try {
      final payload = await aemet.municipalityDaily(code);
      final retrievedAt = DateTime.now().toUtc();
      return Response.ok(
        jsonEncode({
          'data': payload,
          'provenance': {
            'sourceId': 'aemet-opendata',
            'sourceName': 'AEMET OpenData',
            'sourceUrl': 'https://opendata.aemet.es/',
            'retrievedAt': retrievedAt.toIso8601String(),
            'freshnessState': 'fresh',
            'confidence': 1.0,
            'adapterVersion': '0.1.0',
          },
        }),
        headers: _jsonHeaders(),
      );
    } catch (_) {
      return Response(503, body: jsonEncode({'error': 'provider_unavailable'}), headers: _jsonHeaders());
    }
  });

  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(router.call);
  await shelf_io.serve(handler, InternetAddress.anyIPv4, port, poweredByHeader: null);
}

Map<String, String> _jsonHeaders() => const {'content-type': 'application/json; charset=utf-8'};

class _RateWindow {
  const _RateWindow({required this.start, required this.count});
  final DateTime start;
  final int count;
}
