import 'dart:convert';

import 'package:espana_outdoors/core/contracts/routing_service.dart';
import 'package:espana_outdoors/infrastructure/routing/valhalla_routing_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this.payload);

  final Map<String, dynamic> payload;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(payload))),
      200,
      headers: const {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  test('Valhalla route preserves seconds and exposes maneuvers', () async {
    final client = _FakeClient({
      'trip': {
        'legs': [
          {
            'summary': {'length': 1.25, 'time': 120},
            'maneuvers': [
              {
                'instruction': 'Gira a la derecha',
                'length': 0.5,
                'time': 45,
                'begin_shape_index': 0,
                'end_shape_index': 1,
              },
            ],
            'shape': {
              'type': 'LineString',
              'coordinates': [
                [-3.70, 40.41],
                [-3.69, 40.42],
              ],
            },
          },
        ],
      },
    });

    final service = ValhallaRoutingService(
      baseUri: Uri.parse('https://routing.example.com/'),
      client: client,
    );
    final result = await service.route(
      const RouteRequest(
        points: [LatLng(40.41, -3.70), LatLng(40.42, -3.69)],
      ),
    );

    expect(result.distanceMeters, 1250);
    expect(result.durationSeconds, 120);
    expect(result.points, hasLength(2));
    expect(result.steps, hasLength(1));
    expect(result.steps.single.instruction, 'Gira a la derecha');
    expect(result.steps.single.distanceMeters, 500);
  });
}
