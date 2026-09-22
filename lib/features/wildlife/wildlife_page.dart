import 'package:flutter/material.dart';

import 'wildlife_guidance.dart';

class WildlifePage extends StatefulWidget {
  const WildlifePage({super.key});

  @override
  State<WildlifePage> createState() => _WildlifePageState();
}

class _WildlifePageState extends State<WildlifePage> {
  final _catalog = const WildlifeGuidanceCatalog();
  String _species = 'Jabalí';

  @override
  Widget build(BuildContext context) {
    final guidance = _catalog.forSpecies(_species);

    return Scaffold(
      appBar: AppBar(title: const Text('Fauna')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Encuentros con fauna',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Orientación preventiva. La identificación no debe hacerse acercándose al animal.',
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Jabalí', label: Text('Jabalí')),
              ButtonSegment(value: 'Serpiente', label: Text('Serpiente')),
              ButtonSegment(value: 'Otro', label: Text('Otro')),
            ],
            selected: {_species},
            onSelectionChanged: (selection) =>
                setState(() => _species = selection.first),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guidance.species,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Qué hacer',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final action in guidance.actions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_forward, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(action)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Evita',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final item in guidance.avoid)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.block_outlined, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
