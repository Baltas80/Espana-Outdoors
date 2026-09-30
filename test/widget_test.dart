import 'package:espana_outdoors/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('España Outdoor renders the current main experience', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EspanaOutdoorApp()),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('España Outdoor'), findsOneWidget);
    expect(find.text('ESPAÑA OUTDOOR'), findsWidgets);
    expect(find.text('Explora España'), findsOneWidget);
    expect(find.text('Rutas'), findsOneWidget);
  });
}
