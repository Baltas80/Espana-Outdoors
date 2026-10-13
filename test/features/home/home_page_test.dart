import 'package:espana_outdoors/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home presents the ad, premium hero, and featured route feed', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(find.text('PUBLICIDAD'), findsOneWidget);
    expect(find.text('Explora España'), findsOneWidget);
    expect(find.text('Explorar rutas'), findsOneWidget);
    expect(find.text('Rutas destacadas'), findsOneWidget);

    final homeScrollView = find.byType(CustomScrollView);
    await tester.drag(homeScrollView, const Offset(0, -620));
    await tester.pumpAndSettle();

    expect(find.text('Rutas'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Naturaleza'), findsOneWidget);
  });

  testWidgets('sponsor banner closes without removing the hero', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cerrar publicidad'));
    await tester.pumpAndSettle();

    expect(find.text('PUBLICIDAD'), findsNothing);
    expect(find.text('Explora España'), findsOneWidget);
  });

  testWidgets('home remains within the viewport on phone and tablet widths', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
