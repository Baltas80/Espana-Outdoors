import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OutdoorVisualHero extends StatelessWidget {
  const OutdoorVisualHero({
    super.key,
    required this.asset,
    required this.title,
    this.subtitle,
  });

  final String asset;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1.7,
        child: Stack(
          fit: StackFit.expand,
          children: [
            OutdoorAssetImage(asset: asset, semanticsLabel: title),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).colorScheme.scrim.withValues(alpha: .78),
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

/// Decodes raster assets near their rendered pixel size and supports SVG marks.
class OutdoorAssetImage extends StatelessWidget {
  const OutdoorAssetImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  });

  final String asset;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    if (asset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(asset, fit: fit, semanticsLabel: semanticsLabel);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cacheWidth = width.isFinite
            ? (width * MediaQuery.devicePixelRatioOf(context))
                  .ceil()
                  .clamp(1, 4096)
                  .toInt()
            : null;

        return Image.asset(
          asset,
          fit: fit,
          alignment: alignment,
          filterQuality: FilterQuality.medium,
          cacheWidth: cacheWidth,
          semanticLabel: semanticsLabel,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: frame == null ? const SizedBox.expand() : child,
            );
          },
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(child: Icon(Icons.landscape_outlined)),
          ),
        );
      },
    );
  }
}

class OutdoorAssetIcon extends StatelessWidget {
  const OutdoorAssetIcon({super.key, required this.asset, this.size = 44});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(asset, fit: BoxFit.contain),
    );
  }
}
