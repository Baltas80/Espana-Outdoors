import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand.dart';
import '../../app/photo_atlas.dart';

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
              centerTitle: false,
              title: Row(
                children: [
                  OutdoorBrandMark(size: 42, dark: dark),
                  const SizedBox(width: 10),
                  const Text('ESPAÑA OUTDOOR'),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 0.82,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const OutdoorPhotoTile(
                              index: 0,
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: 0,
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.25, 0.72, 1],
                                  colors: [
                                    Colors.black.withValues(alpha: 0.05),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.92),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 20,
                              right: 20,
                              top: 22,
                              child: Text(
                                'NATURALEZA · RUTAS · AVENTURA',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                            const Positioned(
                              left: 20,
                              right: 20,
                              bottom: 88,
                              child: Text(
                                'Explora\nDescubre\nVive España',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 33,
                                  height: 0.98,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 18,
                              right: 18,
                              bottom: 18,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.48),
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => context.go('/map'),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.search, color: Colors.white),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Buscar lugares, rutas, pueblos…',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _HomeAction(
                            icon: Icons.route_outlined,
                            label: 'Rutas',
                            onTap: () => context.go('/routes'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HomeAction(
                            icon: Icons.map_outlined,
                            label: 'Mapa',
                            onTap: () => context.go('/map'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HomeAction(
                            icon: Icons.download_for_offline_outlined,
                            label: 'Offline',
                            onTap: () => context.go('/offline'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _HomeAction(
                            icon: Icons.pets_outlined,
                            label: 'Fauna',
                            onTap: () => context.go('/wildlife'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HomeAction(
                            icon: Icons.eco_outlined,
                            label: 'Natura 2000',
                            onTap: () => context.go('/natura'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HomeAction(
                            icon: Icons.location_city_outlined,
                            label: 'Pueblos',
                            onTap: () => context.go('/explore'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Destacados',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        TextButton(
                          onPressed: () => context.go('/explore'),
                          child: const Text('Ver todos'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutdoorImageCard(
                      index: 3,
                      height: 190,
                      title: 'Costa Brava',
                      subtitle: 'Rutas entre calas y acantilados',
                      meta: 'MODERADA · 8,3 km · 2–3 h',
                      onTap: () => context.go('/routes'),
                    ),
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

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 27,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
