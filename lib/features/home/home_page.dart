import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand.dart';
import '../../app/design_system.dart';
import '../../app/outdoor_visuals.dart';
import '../shop/shop_entry_card.dart';
import 'home_sections.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _featuredRoutes = <HomeImageFeedItem>[
    HomeImageFeedItem(
      asset: 'assets/images/routes/lagos_covadonga.webp',
      category: 'ASTURIAS',
      title: 'Lagos de Covadonga',
      caption: 'Picos de Europa · Senderismo',
    ),
    HomeImageFeedItem(
      asset: 'assets/images/routes/cami_de_cavalls.webp',
      category: 'MENORCA',
      title: 'Camí de Cavalls',
      caption: 'Costa mediterránea · Aventura',
    ),
    HomeImageFeedItem(
      asset: 'assets/images/routes/ruta_volcanes_la_palma.webp',
      category: 'LA PALMA',
      title: 'Ruta de los Volcanes',
      caption: 'Paisaje volcánico · Canarias',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shortcuts = <HomeShortcutItem>[
      HomeShortcutItem(
        asset: 'assets/visuals/icons/routes.svg',
        label: 'Rutas',
        onTap: () => context.go('/routes'),
      ),
      HomeShortcutItem(
        asset: 'assets/visuals/icons/map.svg',
        label: 'Mapa',
        onTap: () => context.go('/map'),
      ),
      HomeShortcutItem(
        asset: 'assets/visuals/icons/natura.svg',
        label: 'Naturaleza',
        onTap: () => context.go('/natura'),
      ),
      HomeShortcutItem(
        asset: 'assets/visuals/icons/pets.svg',
        label: 'Mascotas',
        onTap: () => context.go('/pets'),
      ),
      HomeShortcutItem(
        asset: 'assets/visuals/icons/offline.svg',
        label: 'Mapas offline',
        onTap: () => context.go('/offline'),
      ),
      HomeShortcutItem(
        asset: 'assets/visuals/icons/wildlife.svg',
        label: 'Fauna',
        onTap: () => context.go('/wildlife'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 68,
              centerTitle: false,
              title: Row(
                children: [
                  OutdoorBrandMark(size: 40, dark: dark),
                  const SizedBox(width: EOSpacing.sm),
                  Text(
                    'ESPAÑA OUTDOOR',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Perfil',
                  onPressed: () => context.go('/profile'),
                  icon: const Icon(Icons.person_outline),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _CenteredContent(
                  child: HomeSponsorBanner(onOpen: () => context.go('/shop')),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _CenteredContent(
                  child: HomeHeroSection(
                    compactAsset: 'assets/images/routes/lagos_covadonga.webp',
                    wideAsset: 'assets/images/routes/picos_de_europa.webp',
                    onExploreRoutes: () => context.go('/routes'),
                    onOpenMap: () => context.go('/map'),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _CenteredContent(
                  child: HomeImageFeedSection(
                    items: _featuredRoutes,
                    onSelect: (_) => context.go('/routes'),
                    onSeeAll: () => context.go('/routes'),
                  ),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 32, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _CenteredContent(
                  child: HomeSectionHeading(
                    title: 'Explora más',
                    subtitle: 'Todo lo necesario para preparar tu salida',
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final sideInset =
                      (constraints.crossAxisExtent - 1120).clamp(
                        0.0,
                        double.infinity,
                      ) /
                      2;
                  return SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: sideInset),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            HomeShortcutTile(item: shortcuts[index]),
                        childCount: shortcuts.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisExtent: 86,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                    ),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
              sliver: SliverList.builder(
                itemCount: 5,
                itemBuilder: (context, index) => _CenteredContent(
                  child: switch (index) {
                    0 => _SafetyEntryCard(onTap: () => context.go('/safety')),
                    1 => const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: ShopEntryCard(),
                    ),
                    2 => const Padding(
                      padding: EdgeInsets.only(top: 28, bottom: 12),
                      child: HomeSectionHeading(title: 'Antes de salir'),
                    ),
                    3 => const _ReadinessCard(),
                    _ => const SizedBox(height: 8),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredContent extends StatelessWidget {
  const _CenteredContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: child,
    ),
  );
}

class _SafetyEntryCard extends StatelessWidget {
  const _SafetyEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(EOSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(EORadii.lg),
              ),
              child: const OutdoorAssetIcon(
                asset: 'assets/visuals/icons/safety.svg',
                size: 44,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Centro de seguridad',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4),
                  Text('SOS, ubicación, contactos y preparación.'),
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
  const _ReadinessCard();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _ReadinessRow(
            asset: 'assets/visuals/icons/offline.svg',
            label: 'Mapa offline',
            value: 'Preparar',
            onTap: () => context.go('/offline'),
          ),
          const Divider(height: 24),
          const _ReadinessRow(
            asset: 'assets/visuals/icons/map.svg',
            label: 'Ubicación',
            value: 'Disponible',
          ),
          const Divider(height: 24),
          _ReadinessRow(
            asset: 'assets/visuals/icons/safety.svg',
            label: 'Contacto de confianza',
            value: 'Configurar',
            onTap: () => context.go('/safety/contacts'),
          ),
        ],
      ),
    ),
  );
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.asset,
    required this.label,
    required this.value,
    this.onTap,
  });

  final String asset;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(EORadii.md),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          OutdoorAssetIcon(asset: asset, size: 30),
          const SizedBox(width: EOSpacing.md),
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    ),
  );
}
