import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/features/home/home_page.dart';

void main() {
  testWidgets('home exposes the current outdoor experience', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Explora España'), findsOneWidget);
    expect(find.text('Rutas'), findsOneWidget);
  });
}
