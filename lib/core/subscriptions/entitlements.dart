/// Canonical RevenueCat entitlement identifiers.
///
/// Keep product/package IDs in RevenueCat configuration, not in application
/// logic. The app consumes only these stable entitlements.
abstract final class Entitlements {
  static const free = 'free';
  static const premium = 'premium';
  static const professional = 'professional';

  static const all = <String>{free, premium, professional};

  static bool grants(String entitlement, String capability) {
    switch (entitlement) {
      case professional:
        return true;
      case premium:
        return capability != 'professional_only';
      case free:
        return const {
          'map_basic',
          'gps_tracking',
          'route_discovery',
          'gpx_import_export',
          'basic_weather',
          'basic_sos',
          'community_reports',
        }.contains(capability);
      default:
        return false;
    }
  }
}
