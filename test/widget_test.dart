import 'dart:io';

import 'package:espana_outdoors/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

late Directory _hiveDirectory;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _hiveDirectory = await Directory.systemTemp.createTemp(
      'espana-outdoor-widget-test-',
    );
    Hive.init(_hiveDirectory.path);
    await Hive.openBox<Map<dynamic, dynamic>>('offline_regions');
    await Hive.openBox<dynamic>('route_tracking');
  });

  tearDownAll(() async {
    await Hive.close();
    await _hiveDirectory.delete(recursive: true);
  });

  testWidgets('the app opens on the map and exposes route planning', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: EspanaOutdoorApp()));
    await tester.pumpAndSettle();

    expect(find.text('Mapa'), findsWidgets);
    expect(find.text('Planificar ruta'), findsOneWidget);

    await tester.tap(find.text('Planificar ruta'));
    await tester.pumpAndSettle();

    expect(find.text('Ruta de senderismo'), findsOneWidget);
    expect(find.text('SELECCIONAR DESTINO'), findsOneWidget);

    await tester.tap(find.text('SELECCIONAR DESTINO'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Usar destino'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Introduce la latitud.'), findsOneWidget);
    expect(find.text('Introduce la longitud.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'NaN');
    await tester.enterText(find.byType(TextFormField).at(1), '181');
    await tester.tap(find.text('Usar destino'));
    await tester.pumpAndSettle();

    expect(
      find.text('Introduce la latitud como número decimal.'),
      findsOneWidget,
    );
    expect(
      find.text('La longitud debe estar entre −180 y 180.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).at(0), '40,4168');
    await tester.enterText(find.byType(TextFormField).at(1), '-3,7038');
    await tester.tap(find.text('Usar destino'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Destino: 40.41680, -3.70380'), findsOneWidget);
  });
}
