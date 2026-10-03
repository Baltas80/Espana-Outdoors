/// Runtime-only configuration for weather providers.
///
/// Provider credentials must come from a trusted runtime/gateway boundary and
/// must never be committed to source control or persisted by the client.
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
