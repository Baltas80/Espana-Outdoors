enum Entitlement { free, premium, professional }

enum OutdoorCapability {
  basicMaps,
  gpsRecording,
  gpxImportExport,
  basicOffline,
  routePlanning,
  weather,
  routeRisk,
  advancedOffline,
  liveAlerts,
  petMode,
  fauna,
  naturaProtect,
  rescueLink,
  advancedAnalytics,
  professionalTools,
}

/// Central capability policy. Billing remains delegated to RevenueCat; the app
/// consumes entitlements instead of scattering subscription checks throughout UI.
final class EntitlementPolicy {
  const EntitlementPolicy(this.entitlement);

  final Entitlement entitlement;

  bool allows(OutdoorCapability capability) {
    switch (capability) {
      case OutdoorCapability.basicMaps:
      case OutdoorCapability.gpsRecording:
      case OutdoorCapability.routePlanning:
        return true;
      case OutdoorCapability.gpxImportExport:
      case OutdoorCapability.basicOffline:
      case OutdoorCapability.weather:
        return entitlement.index >= Entitlement.free.index;
      case OutdoorCapability.routeRisk:
      case OutdoorCapability.advancedOffline:
      case OutdoorCapability.liveAlerts:
      case OutdoorCapability.petMode:
      case OutdoorCapability.fauna:
      case OutdoorCapability.naturaProtect:
        return entitlement.index >= Entitlement.premium.index;
      case OutdoorCapability.rescueLink:
      case OutdoorCapability.advancedAnalytics:
      case OutdoorCapability.professionalTools:
        return entitlement == Entitlement.professional;
    }
  }
}
