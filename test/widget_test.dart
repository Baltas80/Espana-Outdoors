import 'dart:io';

import 'package:espana_outdoors/app/app.dart';
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
    await tester.pumpWidget(
      const ProviderScope(child: EspanaOutdoorApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mapa'), findsWidgets);
    expect(find.text('Planificar ruta'), findsOneWidget);

    await tester.tap(find.text('Planificar ruta'));
    await tester.pumpAndSettle();

    expect(find.text('Ruta de senderismo'), findsOneWidget);
    expect(find.text('SELECCIONAR DESTINO'), findsOneWidget);
  });
}
