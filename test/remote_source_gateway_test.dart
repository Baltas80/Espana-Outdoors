import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:espana_outdoors/infrastructure/sources/remote_source_gateway.dart';

void main() {
  test('normalizes source health metadata', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/sources/aemet/health');
      return http.Response(
        jsonEncode({
          'kind': 'official',
          'status': 'healthy',
          'observedAt': '2026-09-23T12:00:00Z',
          'expiresAt': '2026-09-23T13:00:00Z',
          'licenseUrl': 'https://example.test/license',
          'attribution': 'AEMET OpenData',
        }),
        200,
      );
    });

    final gateway = RemoteSourceGateway(
      baseUri: Uri.parse('https://api.example.test'),
      client: client,
    );
    final snapshot = await gateway.health('aemet');

    expect(snapshot.sourceId, 'aemet');
    expect(snapshot.status.name, 'healthy');
    expect(snapshot.attribution, 'AEMET OpenData');
  });

  test('accepts normalized data envelopes', () async {
    final client = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'data': [
            {'title': 'Aviso', 'level': 'yellow'},
          ],
        }),
        200,
      );
    });

    final gateway = RemoteSourceGateway(
      baseUri: Uri.parse('https://api.example.test/'),
      client: client,
    );
    final records = await gateway.fetch('alerts');

    expect(records.single['title'], 'Aviso');
    expect(records.single['level'], 'yellow');
  });
  test('rejects malformed freshness timestamps instead of inventing current time', () async {
    final client = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'kind': 'official',
          'status': 'healthy',
          'observedAt': 'not-a-timestamp',
        }),
        200,
      );
    });

    final gateway = RemoteSourceGateway(
      baseUri: Uri.parse('https://api.example.test'),
      client: client,
    );

    expect(
      () => gateway.health('aemet'),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects non-HTTPS source gateway endpoints', () async {
    expect(
      () => RemoteSourceGateway(
        baseUri: Uri.parse('http://api.example.test'),
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
      throwsArgumentError,
    );
  });

}
