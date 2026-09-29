import 'package:espana_outdoors/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('España Outdoor renders the main experience', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EspanaOutdoorApp()),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('España Outdoor'), findsOneWidget);
    expect(find.text('ESPAÑA OUTDOOR'), findsNWidgets(2));
    expect(find.text('Buscar lugares, rutas, pueblos…'), findsOneWidget);
    expect(find.text('Rutas'), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
  });
}
