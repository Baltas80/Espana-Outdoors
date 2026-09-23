import 'package:espana_outdoors/core/weather/weather_runtime_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeatherRuntimeConfig', () {
    final now = DateTime.utc(2026, 9, 23, 13);

    test('accepts configured credentials before expiry', () {
      const config = WeatherRuntimeConfig(
        apiKey: 'runtime-key',
        expiresAt: DateTime.utc(2026, 10, 15),
      );

      expect(config.isUsableAt(now), isTrue);
      expect(() => config.validate(now), returnsNormally);
    });

    test('rejects expired credentials', () {
      const config = WeatherRuntimeConfig(
        apiKey: 'runtime-key',
        expiresAt: DateTime.utc(2026, 9, 23, 12, 59),
      );

      expect(config.isUsableAt(now), isFalse);
      expect(
        () => config.validate(now),
        throwsA(isA<WeatherConfigurationException>()),
      );
    });

    test('rejects an empty credential', () {
      const config = WeatherRuntimeConfig(
        apiKey: '',
        expiresAt: DateTime.utc(2026, 10, 15),
      );

      expect(config.isUsableAt(now), isFalse);
      expect(
        () => config.validate(now),
        throwsA(isA<WeatherConfigurationException>()),
      );
    });
  });
}
