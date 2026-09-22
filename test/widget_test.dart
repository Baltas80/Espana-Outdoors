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
    expect(
      find.text('Centro de seguridad', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Antes de salir', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Rutas', skipOffstage: false), findsOneWidget);
    expect(find.bySemanticsLabel('España Outdoor'), findsOneWidget);
  });
}
