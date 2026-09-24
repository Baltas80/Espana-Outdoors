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
    expect(find.bySemanticsLabel('España Outdoor'), findsOneWidget);

    // The Home navigation entry is represented by an icon/route rather than
    // a visible "Rutas" label in the current mobile design. Validate the
    // actual scrollable content instead of coupling the smoke test to a label
    // that is not rendered on this surface.
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
