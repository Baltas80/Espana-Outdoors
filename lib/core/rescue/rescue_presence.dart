import '../domain/outdoor_models.dart';
import 'rescue_link_policy.dart';

class RescuePresence {
  const RescuePresence({
    required this.alertId,
    required this.anonymousResponderId,
    required this.position,
    required this.seenAt,
    this.accepted = false,
  });

  final String alertId;
  final String anonymousResponderId;
  final GeoPoint position;
  final DateTime seenAt;
  final bool accepted;

  bool isVisibleToRequester(RescueLinkAlert alert) {
    if (alert.expired) return false;
    return alert.policy.visibility != RescueVisibility.anonymous;
  }
}
