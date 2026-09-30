import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/features/home/home_page.dart';
import 'package:espana_outdoors/app/outdoor_visuals.dart';

void main() {
  testWidgets('home exposes the current outdoor hero and map actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Explora España'), findsOneWidget);
    expect(find.text('Centro de seguridad'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is OutdoorAssetIcon &&
            widget.asset == 'assets/visuals/icons/map.svg',
      ),
      findsNWidgets(2),
    );
  });
}
