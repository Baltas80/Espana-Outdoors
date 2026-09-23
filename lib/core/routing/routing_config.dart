import 'package:flutter/foundation.dart';

/// Runtime configuration for the provider-neutral routing boundary.
///
/// The endpoint is deliberately supplied outside source control. Production
/// deployments should point this at our managed Valhalla instance; local
/// development may use a private LAN/container endpoint.
class RoutingConfig {
  const RoutingConfig({required this.baseUri});

  final Uri? baseUri;

  bool get isConfigured => baseUri != null;

  static RoutingConfig fromEnvironment() {
    const raw = String.fromEnvironment('VALHALLA_BASE_URL');
    if (raw.isEmpty) return const RoutingConfig(baseUri: null);
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      if (kDebugMode) {
        debugPrint('Invalid VALHALLA_BASE_URL; routing remains disabled.');
      }
      return const RoutingConfig(baseUri: null);
    }
    return RoutingConfig(baseUri: uri);
  }
}
