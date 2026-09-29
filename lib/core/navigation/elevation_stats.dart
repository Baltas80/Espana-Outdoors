import 'dart:math' as math;

class ElevationStats {
  const ElevationStats({
    required this.minMeters,
    required this.maxMeters,
    required this.ascentMeters,
    required this.descentMeters,
    required this.samples,
  });

  final double? minMeters;
  final double? maxMeters;
  final double ascentMeters;
  final double descentMeters;
  final int samples;

  bool get hasElevation => samples > 0 && minMeters != null && maxMeters != null;
}

/// Calculates elevation statistics while suppressing small GPS/barometric noise.
/// [noiseThresholdMeters] prevents insignificant oscillations from inflating
/// accumulated ascent/descent.
ElevationStats calculateElevationStats(
  Iterable<double?> elevations, {
  double noiseThresholdMeters = 2.0,
}) {
  double? min;
  double? max;
  double? previous;
  double ascent = 0;
  double descent = 0;
  var samples = 0;

  for (final raw in elevations) {
    if (raw == null || !raw.isFinite) continue;
    final elevation = raw;
    samples++;
    min = min == null ? elevation : math.min(min, elevation);
    max = max == null ? elevation : math.max(max, elevation);

    if (previous != null) {
      final delta = elevation - previous;
      if (delta >= noiseThresholdMeters) {
        ascent += delta;
      } else if (delta <= -noiseThresholdMeters) {
        descent += -delta;
      }
    }
    previous = elevation;
  }

  return ElevationStats(
    minMeters: min,
    maxMeters: max,
    ascentMeters: ascent,
    descentMeters: descent,
    samples: samples,
  );
}