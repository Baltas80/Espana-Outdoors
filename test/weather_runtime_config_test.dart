import 'package:espana_outdoors/core/weather/weather_runtime_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts configured non-expired credentials', () {
    final config = WeatherRuntimeConfig(
      apiKey: 'test',
      expiresAt: DateTime.utc(2026, 10, 15),
    );

    expect(config.isUsableAt(DateTime.utc(2026, 9, 23)), isTrue);
    expect(() => config.validate(DateTime.utc(2026, 9, 23)), returnsNormally);
  });

  test('rejects missing credentials', () {
    final config = WeatherRuntimeConfig(
      apiKey: '',
      expiresAt: DateTime.utc(2026, 10, 15),
    );

    expect(
      () => config.validate(DateTime.utc(2026, 9, 23)),
      throwsA(isA<WeatherConfigurationException>()),
    );
  });

  test('rejects expired credentials', () {
    final config = WeatherRuntimeConfig(
      apiKey: 'expired',
      expiresAt: DateTime.utc(2026, 9, 22),
    );

    expect(
      () => config.validate(DateTime.utc(2026, 9, 23)),
      throwsA(isA<WeatherConfigurationException>()),
    );
  });
}
