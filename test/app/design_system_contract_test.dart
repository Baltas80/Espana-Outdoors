import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/app/design_system.dart';

void main() {
  test('design system tokens are canonical and stable', () {
    expect(EOColors.night.value, 0xFF06161A);
    expect(EOColors.green.value, 0xFF16A34A);
    expect(EOSpacing.lg, 16);
    expect(EORadii.lg, 16);
    expect(EOTextStyles.hero.fontSize, 32);
    expect(EOTextStyles.hero.fontWeight, FontWeight.w700);
    expect(EOShadows.card.single.blurRadius, 18);
  });

  testWidgets('public design-system barrel exposes core components', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EOButton(label: 'Probar', onPressed: () {}),
        ),
      ),
    );

    expect(find.byType(EOButton), findsOneWidget);
    expect(find.text('Probar'), findsOneWidget);
  });
}
