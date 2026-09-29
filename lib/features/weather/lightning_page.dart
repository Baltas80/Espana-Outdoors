import 'package:flutter/material.dart';

import '../../core/weather/lightning_distance.dart';

class LightningPage extends StatefulWidget {
  const LightningPage({super.key});

  @override
  State<LightningPage> createState() => _LightningPageState();
}

class _LightningPageState extends State<LightningPage> {
  final _controller = TextEditingController();
  LightningDistance? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _calculate() {
    final seconds = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (seconds == null || seconds < 0) {
      setState(() => _result = null);
      return;
    }
    setState(() => _result = LightningDistance.fromThunderDelay(seconds));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Distancia de tormenta')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Calcula la distancia de un rayo', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Cuenta los segundos entre el destello y el trueno e introdúcelos aquí.'),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Segundos', suffixText: 's', border: OutlineInputBorder()),
                  onSubmitted: (_) => _calculate(),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: _calculate, icon: const Icon(Icons.bolt), label: const Text('Calcular')), 
              ]),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_result!.distanceKm.toStringAsFixed(2)} km', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${_result!.distanceMeters.round()} m aproximadamente'),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Estimación basada en una velocidad del sonido aproximada de 343 m/s. El viento, la temperatura y la topografía pueden alterar el resultado. No sustituye las alertas meteorológicas oficiales.'),
        ],
      ),
    );
  }
}
