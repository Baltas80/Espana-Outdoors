import 'package:flutter/material.dart';
import '../../app/outdoor_visuals.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('España Outdoor'),
              actions: [
                IconButton(
                  tooltip: 'Perfil',
                  onPressed: () => context.go('/profile'),
                  icon: const Icon(Icons.person_outline),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        OutdoorBrandMark(size: 56, dark: dark),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ESPAÑA OUTDOOR', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                              SizedBox(height: 3),
                              Text('Explora España. Hazlo preparado.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const OutdoorVisualHero(asset: 'assets/visuals/hero_routes.svg', title: 'Explora España', subtitle: 'Rutas, naturaleza y seguridad en una sola experiencia.'),
                    const SizedBox(height: 24),
                    Text('Hola, explorador', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Naturaleza, aventura y seguridad en un solo lugar.'),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _QuickAction(asset: 'assets/visuals/icons/routes.svg', label: 'Rutas', onTap: () => context.go('/routes'))),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickAction(asset: 'assets/visuals/icons/map.svg', label: 'Mapa', onTap: () => context.go('/map'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _QuickAction(asset: 'assets/visuals/icons/pets.svg', label: 'Mascotas', onTap: () => context.go('/pets'))),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickAction(asset: 'assets/visuals/icons/wildlife.svg', label: 'Fauna', onTap: () => context.go('/wildlife'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _QuickAction(asset: 'assets/visuals/icons/alerts.svg', label: 'Alertas', onTap: () => context.go('/alerts'))),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickAction(asset: 'assets/visuals/icons/natura.svg', label: 'Natura', onTap: () => context.go('/natura'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _QuickAction(asset: 'assets/visuals/icons/rescue.svg', label: 'Rescue Link', onTap: () => context.go('/rescue')),
                    const SizedBox(height: 12),
                    _InstrumentAction(onTap: () => context.go('/instruments')),
                    const SizedBox(height: 24),
                    Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => context.go('/safety'),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(14)),
                                child: const OutdoorAssetIcon(asset: 'assets/visuals/icons/safety.svg', size: 44),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Centro de seguridad', style: TextStyle(fontWeight: FontWeight.w800)),
                                    SizedBox(height: 4),
                                    Text('SOS, alertas, contactos y preparación'),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Antes de salir', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    _ReadinessCard(onOffline: () => context.go('/offline'), onContacts: () => context.go('/safety/contacts')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.asset, required this.label, required this.onTap});
  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutdoorAssetIcon(asset: asset, size: 32),
                const SizedBox(width: 9),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}

class _InstrumentAction extends StatelessWidget {
  const _InstrumentAction({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            child: Row(
              children: [
                Icon(Icons.explore_outlined, size: 32, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Instrumentos de campo', style: TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(height: 3),
                      Text('Brújula, presión y altitud del dispositivo'),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.onOffline, required this.onContacts});
  final VoidCallback onOffline;
  final VoidCallback onContacts;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _ReadinessRow(asset: 'assets/visuals/icons/offline.svg', label: 'Mapa offline', value: 'Preparar', onTap: onOffline),
              const Divider(height: 24),
              const _ReadinessRow(asset: 'assets/visuals/icons/map.svg', label: 'Ubicación', value: 'Al iniciar'),
              const Divider(height: 24),
              _ReadinessRow(asset: 'assets/visuals/icons/safety.svg', label: 'Contacto de confianza', value: 'Configurar', onTap: onContacts),
            ],
          ),
        ),
      );
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({required this.asset, required this.label, required this.value, this.onTap});
  final String asset;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              OutdoorAssetIcon(asset: asset, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
              Text(value, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      );
}
