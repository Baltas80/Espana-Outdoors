import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/features/home/home_page.dart';

void main() {
  testWidgets('home includes the LAND-01 visual hero', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pump();

    expect(find.bySemanticsLabel('Explora España'), findsOneWidget);
  });
}
