import 'package:flutter/material.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  static const _sources = <({String name, String description, IconData icon})>[
    (
      name: 'AEMET',
      description: 'Meteorología y avisos meteorológicos oficiales.',
      icon: Icons.cloud_outlined,
    ),
    (
      name: 'Protección Civil',
      description: 'Emergencias, avisos y recomendaciones oficiales.',
      icon: Icons.campaign_outlined,
    ),
    (
      name: 'MITECO',
      description: 'Incendios, medio ambiente y datos territoriales.',
      icon: Icons.local_fire_department_outlined,
    ),
    (
      name: 'Fuentes territoriales',
      description: 'Comunidades autónomas y administraciones competentes.',
      icon: Icons.account_balance_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas y riesgos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined,
                      size: 32, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('Información verificable',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                  const SizedBox(height: 8),
                  const Text(
                    'Las alertas activas se mostrarán únicamente cuando una fuente válida esté conectada y haya datos verificables. No se generan alertas ficticias.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Fuentes previstas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 10),
          for (final source in _sources) ...[
            Card(
              child: ListTile(
                leading: Icon(source.icon),
                title: Text(source.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(source.description),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Text(
            'España Outdoor no sustituye a 112, ES-Alert, Protección Civil ni a las autoridades competentes. Una ausencia de aviso no significa ausencia de riesgo.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
