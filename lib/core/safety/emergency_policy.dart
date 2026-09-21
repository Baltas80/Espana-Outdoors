/// Safety policy for SOS and Rescue Link.
///
/// This layer deliberately does not place an emergency service behind a
/// community workflow. Official emergency services and trusted contacts are
/// always the primary escalation paths; nearby helpers are optional.
library;

import '../domain/outdoor_models.dart';

class EmergencyPolicy {
  const EmergencyPolicy._();

  static const int nearbyAlertRadiusMeters = 5000;
  static const Duration nearbyAlertTtl = Duration(minutes: 30);
  static const Duration locationShareTtl = Duration(hours: 1);

  static bool shouldOfferRescueLink({
    required EmergencySnapshot snapshot,
    required bool userEnabled,
  }) {
    if (!userEnabled) return false;
    if (snapshot.accuracyMeters.isNaN || snapshot.accuracyMeters <= 0) {
      return false;
    }
    return snapshot.accuracyMeters <= 500;
  }

  static List<String> escalationOrder() => const [
        'official_emergency_services',
        'trusted_contacts',
        'nearby_rescue_link_helpers',
      ];
}
