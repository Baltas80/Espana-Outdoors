import 'package:espana_outdoors/core/contracts/routing_service.dart';
import 'package:espana_outdoors/features/routes/route_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('shows endpoints, route totals, and every returned direction', (
    tester,
  ) async {
    const route = RouteResult(
      points: [LatLng(40.4168, -3.7038), LatLng(40.42, -3.7)],
      distanceMeters: 1250,
      durationSeconds: 5400,
      steps: [
        RouteStep(
          instruction: 'Continúa por el sendero',
          distanceMeters: 750,
          durationSeconds: 1800,
        ),
        RouteStep(
          instruction: 'Gira a la derecha en el cruce',
          distanceMeters: 500,
        ),
        RouteStep(instruction: 'Llega al destino'),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 380,
              height: 360,
              child: RoutePreviewCard(
                origin: LatLng(40.4168, -3.7038),
                destination: LatLng(40.42, -3.7),
                route: route,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Vista previa de la ruta'), findsOneWidget);
    expect(find.text('Origen'), findsOneWidget);
    expect(find.text('Destino'), findsOneWidget);
    expect(find.text('40.41680, -3.70380'), findsOneWidget);
    expect(find.text('40.42000, -3.70000'), findsOneWidget);
    expect(find.text('1.25 km'), findsOneWidget);
    expect(find.text('1 h 30 min'), findsOneWidget);
    expect(find.text('Instrucciones (3)'), findsOneWidget);
    expect(find.text('750 m · 30 min'), findsOneWidget);
    expect(find.text('Continúa por el sendero'), findsOneWidget);
    expect(find.text('Gira a la derecha en el cruce'), findsOneWidget);
    expect(find.text('Llega al destino'), findsOneWidget);

    await tester.ensureVisible(find.text('Llega al destino'));
    expect(find.text('Llega al destino'), findsOneWidget);
  });

  testWidgets('explains when routing returns no steps or summary values', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RoutePreviewCard(
            origin: LatLng(40, -4),
            destination: LatLng(41, -3),
            route: RouteResult(points: [LatLng(40, -4), LatLng(41, -3)]),
          ),
        ),
      ),
    );

    expect(find.text('No disponible'), findsNWidgets(2));
    expect(find.text('Instrucciones (0)'), findsOneWidget);
    expect(
      find.text('El servicio de rutas no devolvió instrucciones paso a paso.'),
      findsOneWidget,
    );
  });

  test('formats distances and durations without inventing missing values', () {
    expect(formatRouteDistance(825), '825 m');
    expect(formatRouteDistance(1234), '1.23 km');
    expect(formatRouteDistance(double.nan), 'No disponible');
    expect(formatRouteDuration(30), '1 min');
    expect(formatRouteDuration(1), '<1 min');
    expect(formatRouteDuration(3600), '1 h');
    expect(formatRouteDuration(-1), 'No disponible');
  });
}
