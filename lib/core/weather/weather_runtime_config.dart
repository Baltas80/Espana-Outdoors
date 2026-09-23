/// Runtime-only configuration required by production weather providers.
///
/// The API key must be supplied by a trusted runtime/gateway boundary; this
/// class deliberately does not load secrets from source-controlled files.
/// `expiresAt` is mandatory so provider credential rotation becomes a
/// testable application concern rather than an operational surprise.
class WeatherRuntimeConfig {
  const WeatherRuntimeConfig({
    required this.apiKey,
    required this.expiresAt,
  });

  final String apiKey;
  final DateTime expiresAt;

  bool get isConfigured => apiKey.trim().isNotEmpty;

  bool isUsableAt(DateTime now) =>
      isConfigured && expiresAt.isAfter(now.toUtc());

  void validate(DateTime now) {
    if (!isConfigured) {
      throw const WeatherConfigurationException(
        'Configuración meteorológica ausente.',
      );
    }
    if (!expiresAt.isAfter(now.toUtc())) {
      throw const WeatherConfigurationException(
        'Credencial meteorológica expirada; requiere rotación.',
      );
    }
  }
}

class WeatherConfigurationException implements Exception {
  const WeatherConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'WeatherConfigurationException($message)';
}
