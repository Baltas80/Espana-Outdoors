import 'package:flutter/material.dart';

import '../../core/weather/weather_models.dart';

/// Consistent weather icon family for the design system.
///
/// Storm deliberately reuses the rain composition and adds a lightning bolt;
/// it is not a separate visual language.
class WeatherIcon extends StatelessWidget {
  const WeatherIcon({
    required this.condition,
    this.size = 32,
    super.key,
  });

  final WeatherCondition condition;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rainColor = theme.colorScheme.primary;
    final accent = theme.colorScheme.secondary;

    final rainy = condition == WeatherCondition.rain ||
        condition == WeatherCondition.storm;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.cloud_outlined,
            size: size,
            color: theme.colorScheme.onSurface,
          ),
          if (rainy)
            Positioned(
              bottom: -size * .08,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Drop(size: size * .18, color: rainColor),
                  SizedBox(width: size * .08),
                  _Drop(size: size * .18, color: rainColor),
                  SizedBox(width: size * .08),
                  _Drop(size: size * .18, color: rainColor),
                ],
              ),
            ),
          if (condition == WeatherCondition.storm)
            Positioned(
              right: size * .16,
              bottom: size * .04,
              child: Icon(
                Icons.bolt,
                size: size * .46,
                color: accent,
              ),
            ),
        ],
      ),
    );
  }
}

class _Drop extends StatelessWidget {
  const _Drop({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.water_drop, size: size, color: color);
  }
}
