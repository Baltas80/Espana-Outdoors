import 'dart:math';

import '../domain/outdoor_models.dart';
import 'rescue_link_policy.dart';

class RescueLinkService {
  const RescueLinkService();

  RescueLinkAlert createAlert({
    required GeoPoint position,
    RescueLinkPolicy policy = const RescueLinkPolicy(),
  }) {
    if (!policy.isValid) {
      throw ArgumentError('Configuración Rescue Link no válida.');
    }

    final now = DateTime.now();
    return RescueLinkAlert(
      id: _id(),
      createdAt: now,
      expiresAt: now.add(policy.ttl),
      policy: policy,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  bool canRespond(RescueLinkAlert alert) {
    return !alert.expiredAt(DateTime.now()) &&
        alert.state == RescueLinkState.active;
  }

  String _id() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(36).toRadixString(36)).join();
  }
}
