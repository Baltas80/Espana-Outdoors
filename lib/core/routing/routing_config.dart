import 'package:flutter/foundation.dart';

/// Runtime configuration for the provider-neutral routing boundary.
final class RoutingConfig {
  const RoutingConfig({
    required this.baseUri,
    this.allowHttpForDevelopment = false,
  });

  final Uri? baseUri;
  final bool allowHttpForDevelopment;

  bool get isConfigured {
    final uri = baseUri;
    if (uri == null || uri.host.isEmpty) return false;
    return uri.scheme == 'https' ||
        (allowHttpForDevelopment && uri.scheme == 'http');
  }

  static RoutingConfig fromEnvironment() {
    const raw = String.fromEnvironment('VALHALLA_BASE_URL');
    const allowHttp = String.fromEnvironment('ALLOW_HTTP_DEV');
    if (raw.isEmpty) return const RoutingConfig(baseUri: null);

    final uri = Uri.tryParse(raw);
    final developmentHttp =
        kDebugMode && allowHttp.toLowerCase().trim() == 'true';
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && !(developmentHttp && uri.scheme == 'http'))) {
      if (kDebugMode) {
        debugPrint('Invalid VALHALLA_BASE_URL; routing remains disabled.');
      }
      return const RoutingConfig(baseUri: null);
    }

    return RoutingConfig(
      baseUri: uri,
      allowHttpForDevelopment: developmentHttp,
    );
  }
}
