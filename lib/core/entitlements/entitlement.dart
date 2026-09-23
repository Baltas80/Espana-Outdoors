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
/// Safety-critical SOS/Rescue Link access is intentionally not paywalled.
final class EntitlementPolicy {
  const EntitlementPolicy(this.entitlement);

  final Entitlement entitlement;

  bool allows(OutdoorCapability capability) {
    switch (capability) {
      case OutdoorCapability.basicMaps:
      case OutdoorCapability.gpsRecording:
      case OutdoorCapability.gpxImportExport:
      case OutdoorCapability.basicOffline:
      case OutdoorCapability.routePlanning:
      case OutdoorCapability.weather:
      case OutdoorCapability.rescueLink:
        return true;
      case OutdoorCapability.routeRisk:
      case OutdoorCapability.advancedOffline:
      case OutdoorCapability.liveAlerts:
      case OutdoorCapability.petMode:
      case OutdoorCapability.fauna:
      case OutdoorCapability.naturaProtect:
        return entitlement.index >= Entitlement.premium.index;
      case OutdoorCapability.advancedAnalytics:
      case OutdoorCapability.professionalTools:
        return entitlement == Entitlement.professional;
    }
  }
}
