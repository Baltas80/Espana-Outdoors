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
            _VisualAsset(asset: asset, semanticsLabel: title),
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
                  Text(title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(subtitle!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
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

class _VisualAsset extends StatelessWidget {\n  const _VisualAsset({required this.asset, required this.semanticsLabel});\n\n  final String asset;\n  final String semanticsLabel;\n\n  @override\n  Widget build(BuildContext context) {\n    if (asset.toLowerCase().endsWith('.svg')) {\n      return SvgPicture.asset(asset, fit: BoxFit.cover, semanticsLabel: semanticsLabel);\n    }\n    return Image.asset(\n      asset,\n      fit: BoxFit.cover,\n      filterQuality: FilterQuality.high,\n      semanticLabel: semanticsLabel,\n    );\n  }\n}\n\nclass OutdoorAssetIcon extends StatelessWidget {
  const OutdoorAssetIcon({
    super.key,
    required this.asset,
    this.size = 44,
  });

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
