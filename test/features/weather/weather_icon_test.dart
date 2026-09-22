import 'package:espana_outdoors/core/weather/weather_models.dart';
import 'package:espana_outdoors/features/weather/weather_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('storm reuses rain composition and adds a lightning bolt', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WeatherIcon(condition: WeatherCondition.storm),
        ),
      ),
    );

    expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    expect(find.byIcon(Icons.water_drop), findsNWidgets(3));
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });
}
