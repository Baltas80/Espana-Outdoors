import 'package:espana_outdoor/core/navigation/elevation_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates ascent and descent while ignoring small noise', () {
    final stats = calculateElevationStats(<double?>[
      100,
      101,
      103.5,
      103,
      108,
      105,
      null,
    ]);

    expect(stats.samples, 6);
    expect(stats.minMeters, 100);
    expect(stats.maxMeters, 108);
    expect(stats.ascentMeters, 7.5);
    expect(stats.descentMeters, 3);
  });

  test('ignores invalid elevation samples', () {
    final stats = calculateElevationStats(<double?>[
      null,
      double.nan,
      double.infinity,
      200,
    ]);

    expect(stats.samples, 1);
    expect(stats.ascentMeters, 0);
    expect(stats.descentMeters, 0);
  });
}