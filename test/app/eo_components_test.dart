import 'package:espana_outdoors/app/eo_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('premium component system renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          appBar: const EOAppBar(title: 'España Outdoor'),
          body: ListView(
            padding: const EdgeInsets.all(EOSpacing.lg),
            children: [
              const EOButton(label: 'Iniciar ruta', onPressed: null),
              const SizedBox(height: EOSpacing.sm),
              const EOIconButton(icon: Icons.map, onPressed: null),
              const SizedBox(height: EOSpacing.sm),
              const EOCard(child: Text('Ruta')),
              const SizedBox(height: EOSpacing.sm),
              const EOChip(label: 'Moderada', selected: true),
              const SizedBox(height: EOSpacing.sm),
              const EOListTile(title: 'Lagos de Covadonga'),
              const SizedBox(height: EOSpacing.sm),
              const EOMapPanel(child: Text('Mapa')),
              const SizedBox(height: EOSpacing.sm),
              EOSelect<String>(
                value: 'España',
                items: const ['España'],
                onChanged: (_) {},
                labelBuilder: (value) => value,
              ),
              const SizedBox(height: EOSpacing.sm),
              const EOSearchField(),
              const SizedBox(height: EOSpacing.sm),
              const EOGpsControl(onPressed: null),
              const SizedBox(height: EOSpacing.sm),
              const EOMapControls(
                onZoomIn: null,
                onZoomOut: null,
                onLayers: null,
              ),
              const SizedBox(height: EOSpacing.sm),
              const EODownloadIndicator(progress: .5, label: 'Mapa de España'),
              const SizedBox(height: EOSpacing.sm),
              const EONavigationBanner(
                instruction: 'Continúa por el sendero',
                distanceLabel: '320 m',
              ),
            ],
          ),
          bottomNavigationBar: EONavigationBar(
            currentIndex: 1,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('España Outdoor'), findsOneWidget);
    expect(find.text('Iniciar ruta'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mapa de España'),
      300,
      scrollable: find.byType(ListView),
    );
    expect(find.text('Mapa de España'), findsOneWidget);
    expect(find.text('320 m'), findsOneWidget);
    expect(find.text('Mapa'), findsWidgets);
  });
}
