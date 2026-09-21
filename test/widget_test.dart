import 'package:espana_outdoors/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('España Outdoor renders the main experience', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EspanaOutdoorApp()));
    await tester.pumpAndSettle();

    expect(find.text('España Outdoor'), findsOneWidget);
    expect(find.text('Explorar mapa'), findsOneWidget);
    expect(find.text('Centro de seguridad'), findsOneWidget);
  });
}
