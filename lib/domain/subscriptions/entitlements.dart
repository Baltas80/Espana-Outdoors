enum OutdoorPlan { free, premium, professional }

enum OutdoorEntitlement {
  routeDiscovery,
  routePlanning,
  gpsRecording,
  gpxImportExport,
  basicOfflineMaps,
  advancedOfflineMaps,
  liveWeather,
  routeStatus,
  routeSafetyAssessment,
  advancedSafetyAssessment,
  petMode,
  faunaGuide,
  naturaProtect,
  rescueLink,
  trustedContacts,
  advancedAlerts,
  professionalData,
  advancedAnalytics,
  apiAccess,
  prioritySupport,
}

/// Entitlements are the product boundary. UI must not scatter plan checks.
final class EntitlementCatalog {
  static const Map<OutdoorPlan, Set<OutdoorEntitlement>> matrix = {
    OutdoorPlan.free: {
      OutdoorEntitlement.routeDiscovery,
      OutdoorEntitlement.routePlanning,
      OutdoorEntitlement.gpsRecording,
      OutdoorEntitlement.gpxImportExport,
      OutdoorEntitlement.basicOfflineMaps,
      OutdoorEntitlement.liveWeather,
      OutdoorEntitlement.routeStatus,
      OutdoorEntitlement.trustedContacts,
    },
    OutdoorPlan.premium: {
      OutdoorEntitlement.routeDiscovery,
      OutdoorEntitlement.routePlanning,
      OutdoorEntitlement.gpsRecording,
      OutdoorEntitlement.gpxImportExport,
      OutdoorEntitlement.basicOfflineMaps,
      OutdoorEntitlement.advancedOfflineMaps,
      OutdoorEntitlement.liveWeather,
      OutdoorEntitlement.routeStatus,
      OutdoorEntitlement.routeSafetyAssessment,
      OutdoorEntitlement.advancedSafetyAssessment,
      OutdoorEntitlement.petMode,
      OutdoorEntitlement.faunaGuide,
      OutdoorEntitlement.trustedContacts,
      OutdoorEntitlement.advancedAlerts,
    },
    OutdoorPlan.professional: {
      OutdoorEntitlement.routeDiscovery,
      OutdoorEntitlement.routePlanning,
      OutdoorEntitlement.gpsRecording,
      OutdoorEntitlement.gpxImportExport,
      OutdoorEntitlement.basicOfflineMaps,
      OutdoorEntitlement.advancedOfflineMaps,
      OutdoorEntitlement.liveWeather,
      OutdoorEntitlement.routeStatus,
      OutdoorEntitlement.routeSafetyAssessment,
      OutdoorEntitlement.advancedSafetyAssessment,
      OutdoorEntitlement.petMode,
      OutdoorEntitlement.faunaGuide,
      OutdoorEntitlement.naturaProtect,
      OutdoorEntitlement.rescueLink,
      OutdoorEntitlement.trustedContacts,
      OutdoorEntitlement.advancedAlerts,
      OutdoorEntitlement.professionalData,
      OutdoorEntitlement.advancedAnalytics,
      OutdoorEntitlement.apiAccess,
      OutdoorEntitlement.prioritySupport,
    },
  };

  static bool allows(OutdoorPlan plan, OutdoorEntitlement entitlement) =>
      matrix[plan]?.contains(entitlement) ?? false;
}
