import 'weather_models.dart';

/// Provider-neutral contract for weather integrations.
///
/// Features depend on this interface rather than AEMET or any commercial
/// provider, allowing failover and provider replacement without UI changes.
abstract interface class WeatherService {
  Future<WeatherForecast> dailyMunicipalityForecast(String municipalityCode);
}
