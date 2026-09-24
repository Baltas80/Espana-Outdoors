import 'package:espana_outdoors/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('España Outdoor renders the main experience', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EspanaOutdoorApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('España Outdoor'), findsWidgets);
    expect(find.text('ESPAÑA OUTDOOR'), findsOneWidget);
    expect(find.text('Rutas'), findsOneWidget);
    expect(find.bySemanticsLabel('España Outdoor'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Centro de seguridad'),
      500,
      scrollable: scrollable,
    );
    expect(find.text('Centro de seguridad'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Antes de salir'),
      500,
      scrollable: scrollable,
    );
    expect(find.text('Antes de salir'), findsOneWidget);
  });
}
