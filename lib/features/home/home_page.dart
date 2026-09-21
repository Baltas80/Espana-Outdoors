import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                delegate: SliverChildListDelegate([
                  Text('Sal al exterior con más información.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Rutas, naturaleza, condiciones y seguridad en una sola experiencia.'),
                  const SizedBox(height: 24),
                  _ActionCard(
                    icon: Icons.map_outlined,
                    title: 'Explorar mapa',
                    subtitle: 'Rutas, puntos de interés y tu posición.',
                    onTap: () => context.go('/map'),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.shield_outlined,
                    title: 'Centro de seguridad',
                    subtitle: 'SOS, contactos, alertas y preparación.',
                    onTap: () => context.go('/safety'),
                  ),
                  const SizedBox(height: 24),
                  Text('Antes de salir', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const _ReadinessCard(),
                ]),
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
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explorar'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Seguridad'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(radius: 25, child: Icon(icon)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(subtitle)])),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          _ReadinessRow(icon: Icons.map_outlined, label: 'Mapa offline', value: 'Preparar'),
          Divider(height: 24),
          _ReadinessRow(icon: Icons.location_on_outlined, label: 'Ubicación', value: 'Disponible al iniciar'),
          Divider(height: 24),
          _ReadinessRow(icon: Icons.contact_emergency_outlined, label: 'Contacto de confianza', value: 'Configurar'),
        ]),
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon), const SizedBox(width: 12), Expanded(child: Text(label)), Text(value, style: Theme.of(context).textTheme.labelLarge)]);
}
