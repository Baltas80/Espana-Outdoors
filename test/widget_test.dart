import 'package:espana_outdoors/app/app.dart';
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
    expect(find.text('Seguridad'), findsOneWidget);
    expect(find.bySemanticsLabel('España Outdoor'), findsOneWidget);

    // Home uses a lazy sliver list, so the safety card may not be built until
    // it enters the viewport. Exercise the real scroll path instead of
    // weakening the assertion or depending on implementation details.
    await tester.scrollUntilVisible(
      find.text('Centro de seguridad'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Centro de seguridad'), findsOneWidget);
    expect(find.text('Antes de salir'), findsOneWidget);
  });
}
