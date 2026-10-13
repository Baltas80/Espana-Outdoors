import 'package:flutter/material.dart';

import '../../app/design_system.dart';
import '../../app/outdoor_visuals.dart';

/// A first-party sponsor placement with a fixed footprint while visible.
class HomeSponsorBanner extends StatefulWidget {
  const HomeSponsorBanner({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  State<HomeSponsorBanner> createState() => _HomeSponsorBannerState();
}

class _HomeSponsorBannerState extends State<HomeSponsorBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final height = compact ? 94.0 : 84.0;

        return SizedBox(
          height: height,
          child: Material(
            color: EOColors.surface,
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: .2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(EORadii.lg),
              side: const BorderSide(color: EOColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: EOColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(EORadii.md),
                    ),
                    child: const Icon(
                      Icons.backpack_outlined,
                      color: EOColors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PUBLICIDAD',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: EOColors.orange,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Equipo para cada salida',
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: EOColors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onOpen,
                    style: TextButton.styleFrom(
                      foregroundColor: EOColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(compact ? 'Tienda' : 'Ver tienda'),
                  ),
                  IconButton(
                    tooltip: 'Cerrar publicidad',
                    onPressed: () => setState(() => _dismissed = true),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Responsive editorial hero; the image box keeps its size before decoding.
class HomeHeroSection extends StatelessWidget {
  const HomeHeroSection({
    required this.compactAsset,
    required this.wideAsset,
    required this.onExploreRoutes,
    required this.onOpenMap,
    super.key,
  });

  final String compactAsset;
  final String wideAsset;
  final VoidCallback onExploreRoutes;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 640;
      final height = wide
          ? (constraints.maxWidth * .46).clamp(320.0, 440.0)
          : (constraints.maxWidth * 1.22).clamp(390.0, 440.0);

      return ClipRRect(
        borderRadius: BorderRadius.circular(EORadii.xl + 4),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              OutdoorAssetImage(
                asset: wide ? wideAsset : compactAsset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                semanticsLabel: wide
                    ? 'Paisaje de montaña en España'
                    : 'Senderista junto a los Lagos de Covadonga',
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .08),
                      Colors.black.withValues(alpha: .14),
                      Colors.black.withValues(alpha: .82),
                    ],
                    stops: const [0, .36, 1],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(wide ? 28 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroEyebrow(wide: wide),
                    const Spacer(),
                    Text(
                      'Explora España',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontSize: wide ? 42 : 34,
                            fontWeight: FontWeight.w900,
                            height: 1.04,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 12),
                            ],
                          ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Text(
                        'Rutas, naturaleza y aventura para tu próxima salida.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: onExploreRoutes,
                          icon: const Icon(Icons.explore_outlined),
                          label: const Text('Explorar rutas'),
                          style: FilledButton.styleFrom(
                            backgroundColor: EOColors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onOpenMap,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Ver mapa'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _HeroEyebrow extends StatelessWidget {
  const _HeroEyebrow({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .36),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: .3)),
    ),
    child: Text(
      wide ? 'NATURALEZA  ·  RUTAS  ·  AVENTURA' : 'TODA ESPAÑA, AHÍ FUERA',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    ),
  );
}

class HomeImageFeedItem {
  const HomeImageFeedItem({
    required this.asset,
    required this.category,
    required this.title,
    required this.caption,
  });

  final String asset;
  final String category;
  final String title;
  final String caption;
}

/// Horizontally virtualized editorial cards for featured routes and places.
class HomeImageFeedSection extends StatelessWidget {
  const HomeImageFeedSection({
    required this.items,
    required this.onSelect,
    required this.onSeeAll,
    super.key,
  });

  final List<HomeImageFeedItem> items;
  final ValueChanged<HomeImageFeedItem> onSelect;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth * .76)
          .clamp(250.0, 320.0)
          .toDouble();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeading(
            title: 'Rutas destacadas',
            subtitle: 'Paisajes para tu próxima escapada',
            actionLabel: 'Ver todas',
            onAction: onSeeAll,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 236,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1 ? 0 : EOSpacing.md,
                ),
                child: _HomeImageCard(
                  item: items[index],
                  width: cardWidth,
                  onTap: () => onSelect(items[index]),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class HomeSectionHeading extends StatelessWidget {
  const HomeSectionHeading({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
      if (actionLabel != null && onAction != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

class HomeShortcutItem {
  const HomeShortcutItem({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;
}

class HomeShortcutTile extends StatelessWidget {
  const HomeShortcutTile({required this.item, super.key});

  final HomeShortcutItem item;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            OutdoorAssetIcon(asset: item.asset, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    ),
  );
}

class _HomeImageCard extends StatelessWidget {
  const _HomeImageCard({
    required this.item,
    required this.width,
    required this.onTap,
  });

  final HomeImageFeedItem item;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${item.title}. ${item.category}. ${item.caption}',
    child: Material(
      borderRadius: BorderRadius.circular(EORadii.xl),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: .22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Stack(
            fit: StackFit.expand,
            children: [
              OutdoorAssetImage(
                asset: item.asset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                semanticsLabel: item.title,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .06),
                      Colors.transparent,
                      Colors.black.withValues(alpha: .84),
                    ],
                    stops: const [0, .36, 1],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    item.category.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
