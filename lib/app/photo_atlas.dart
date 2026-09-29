import 'package:flutter/material.dart';

class OutdoorPhotoTile extends StatelessWidget {
  const OutdoorPhotoTile({
    super.key,
    required this.index,
    this.width = 120,
    this.height = 60,
    this.borderRadius = 18,
  });

  final int index;
  final double width;
  final double height;
  final double borderRadius;

  static const _asset = 'assets/visuals/outdoor_photo_atlas.jpg';
  static const _tileWidth = 120.0;
  static const _tileHeight = 60.0;
  static const _atlasWidth = 480.0;
  static const _atlasHeight = 180.0;
  static const _columns = 4;

  @override
  Widget build(BuildContext context) {
    final safeIndex = index.clamp(0, 11);
    final column = safeIndex % _columns;
    final row = safeIndex ~/ _columns;
    final scale = width / _tileWidth;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRect(
          child: Transform.scale(
            alignment: Alignment.topLeft,
            scale: scale,
            child: Transform.translate(
              offset: Offset(
                -column * _tileWidth,
                -row * _tileHeight,
              ),
              child: SizedBox(
                width: _atlasWidth,
                height: _atlasHeight,
                child: Image.asset(
                  _asset,
                  width: _atlasWidth,
                  height: _atlasHeight,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OutdoorPhotoHero extends StatelessWidget {
  const OutdoorPhotoHero({
    super.key,
    required this.index,
    required this.title,
    this.subtitle,
    this.aspectRatio = 1.36,
  });

  final int index;
  final String title;
  final String? subtitle;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            OutdoorPhotoTile(
              index: index,
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.3, 1],
                  colors: [
                    Colors.transparent,
                    Theme.of(context).colorScheme.scrim.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OutdoorImageCard extends StatelessWidget {
  const OutdoorImageCard({
    super.key,
    required this.index,
    required this.title,
    required this.subtitle,
    this.meta,
    this.height = 220,
    this.onTap,
  });

  final int index;
  final String title;
  final String subtitle;
  final String? meta;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            OutdoorPhotoTile(
              index: index,
              width: double.infinity,
              height: height,
              borderRadius: 0,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.25, 1],
                  colors: [
                    Colors.transparent,
                    Theme.of(context).colorScheme.scrim.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (meta != null) ...[
                    Text(
                      meta!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return onTap == null
        ? card
        : Semantics(
            button: true,
            label: title,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: card,
            ),
          );
  }
}
