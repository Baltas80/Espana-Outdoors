import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../domain/subscriptions/entitlements.dart';
import '../../infrastructure/subscriptions/revenuecat_subscription_service.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {

  final _subscriptions = RevenueCatSubscriptionService.fromEnvironment();

  static const _features = <({String label, OutdoorEntitlement entitlement})>[
    (label: 'Descubrimiento y planificación de rutas', entitlement: OutdoorEntitlement.routeDiscovery),
    (label: 'GPS y grabación', entitlement: OutdoorEntitlement.gpsRecording),
    (label: 'Importar y exportar GPX', entitlement: OutdoorEntitlement.gpxImportExport),
    (label: 'Mapas offline avanzados', entitlement: OutdoorEntitlement.advancedOfflineMaps),
    (label: 'Evaluación de seguridad de ruta', entitlement: OutdoorEntitlement.routeSafetyAssessment),
    (label: 'Modo Mascota', entitlement: OutdoorEntitlement.petMode),
    (label: 'Guía de fauna', entitlement: OutdoorEntitlement.faunaGuide),
    (label: 'NATURA PROTECT', entitlement: OutdoorEntitlement.naturaProtect),
    (label: 'Rescue Link', entitlement: OutdoorEntitlement.rescueLink),
    (label: 'Alertas avanzadas', entitlement: OutdoorEntitlement.advancedAlerts),
    (label: 'Datos profesionales', entitlement: OutdoorEntitlement.professionalData),
    (label: 'API y analítica avanzada', entitlement: OutdoorEntitlement.apiAccess),
  ];

  String _planName(OutdoorPlan plan) => switch (plan) {
        OutdoorPlan.free => 'FREE',
        OutdoorPlan.premium => 'PREMIUM',
        OutdoorPlan.professional => 'PROFESSIONAL',
      };

  Future<void> _openPremium() async {
    try {
      await _subscriptions.configure();
      await RevenueCatUI.presentPaywallIfNeeded('premium');
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suscripciones no disponibles: $error')),
      );
    }
  }

  Future<void> _restore() async {
    try {
      await _subscriptions.configure();
      await _subscriptions.restorePurchases();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compras restauradas.')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron restaurar las compras: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text('Elige cómo quieres explorar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 8),
          const Text('Las capacidades se controlan mediante entitlements, no mediante comprobaciones dispersas en la interfaz.'),
          FilledButton.icon(
            onPressed: _openPremium,
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Ver opciones de suscripción'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _restore,
            icon: const Icon(Icons.restore),
            label: const Text('Restaurar compras'),
          ),
          const SizedBox(height: 20),
          for (final plan in OutdoorPlan.values) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_planName(plan),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            )),
                    const SizedBox(height: 12),
                    for (final feature in _features)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Icon(
                              EntitlementCatalog.allows(plan, feature.entitlement)
                                  ? Icons.check_circle_outline
                                  : Icons.remove_circle_outline,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(feature.label)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Las funciones críticas de emergencia no deben depender de una suscripción para funcionar. Los productos comerciales y entitlements se activarán mediante RevenueCat cuando las cuentas de tienda y backend estén configuradas.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
