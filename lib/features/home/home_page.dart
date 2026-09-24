import 'package:flutter/material.dart';
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
                    const _HomeHero(),
                    const SizedBox(height: 24),
                    Text('Hola, explorador', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Naturaleza, aventura y seguridad en un solo lugar.'),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _QuickAction(icon: Icons.route_outlined, label: 'Rutas', onTap: () => context.go('/routes'))),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickAction(icon: Icons.map_outlined, label: 'Mapa', onTap: () => context.go('/map'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _QuickAction(icon: Icons.pets_outlined, label: 'Mascotas', onTap: () => context.go('/pets'))),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickAction(icon: Icons.forest_outlined, label: 'Fauna', onTap: () => context.go('/wildlife'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _QuickAction(icon: Icons.campaign_outlined, label: 'Alertas', onTap: () => context.go('/alerts'))),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickAction(icon: Icons.eco_outlined, label: 'Natura', onTap: () => context.go('/natura'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _QuickAction(icon: Icons.link_outlined, label: 'Rescue Link', onTap: () => context.go('/rescue')),
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
                                child: Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.onErrorContainer),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) context.go('/map');
          if (index == 2) context.go('/safety');
          if (index == 3) context.go('/profile');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Seguridad'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: 1.65,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/landscapes/picos_europa.jpg',
              fit: BoxFit.cover,
              semanticLabel: 'Paisaje de montaña de España',
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.35, 1],
                  colors: [
                    Colors.transparent,
                    Theme.of(context).colorScheme.scrim.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Text(
                'Descubre España a pie, con tu gente y con tu compañero de aventura.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
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
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
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
                Icon(icon, size: 25),
                const SizedBox(width: 9),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
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
              _ReadinessRow(icon: Icons.map_outlined, label: 'Mapa offline', value: 'Preparar', onTap: onOffline),
              const Divider(height: 24),
              const _ReadinessRow(icon: Icons.location_on_outlined, label: 'Ubicación', value: 'Al iniciar'),
              const Divider(height: 24),
              _ReadinessRow(icon: Icons.contact_emergency_outlined, label: 'Contacto de confianza', value: 'Configurar', onTap: onContacts),
            ],
          ),
        ),
      );
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({required this.icon, required this.label, required this.value, this.onTap});
  final IconData icon;
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
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
              Text(value, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      );
}
