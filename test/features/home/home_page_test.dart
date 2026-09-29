import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/features/home/home_page.dart';

void main() {
  testWidgets('home exposes the premium outdoor hero and map action', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(find.text('NATURALEZA · RUTAS · AVENTURA'), findsOneWidget);
    expect(find.textContaining('Explora'), findsOneWidget);
    expect(find.text('Buscar lugares, rutas, pueblos…'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
