import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/outdoor_models.dart';
import 'trusted_contact.dart';

class EmergencyShareService {
  const EmergencyShareService();

  EmergencySharePayload createPayload({
    required EmergencySnapshot snapshot,
    Duration ttl = const Duration(minutes: 30),
  }) {
    if (ttl.inSeconds <= 0) {
      throw ArgumentError.value(ttl, 'ttl', 'must be positive');
    }
    final expiresAt = DateTime.now().toUtc().add(ttl);
    return EmergencySharePayload(
      snapshot: snapshot,
      expiresAt: expiresAt,
      shareToken: _localCorrelationCode(snapshot, expiresAt),
    );
  }

  Future<void> copyShareText(EmergencySharePayload payload) async {
    await Clipboard.setData(ClipboardData(text: buildShareText(payload)));
  }

  Future<bool> openSms(EmergencySharePayload payload, String phone) async {
    if (payload.expired || phone.trim().isEmpty) return false;
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': buildShareText(payload)},
    );
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  String buildShareText(EmergencySharePayload payload) {
    if (payload.expired) {
      return 'ALERTA España Outdoor. El aviso ha caducado.';
    }
    final p = payload.snapshot.position;
    final lat = _roundHundredth(p.latitude);
    final lon = _roundHundredth(p.longitude);
    return 'ALERTA España Outdoor. Ubicación aproximada: ' +
        lat.toStringAsFixed(2) + ', ' +
        lon.toStringAsFixed(2) +
        '. Precisión GPS aproximada: ' +
        payload.snapshot.accuracyMeters.toStringAsFixed(0) +
        ' m. Tipo: ' +
        payload.snapshot.type.name +
        '. Válida hasta ' +
        payload.expiresAt.toLocal().toIso8601String() +
        '. Código de aviso: ' +
        payload.shareToken;
  }

  double _roundHundredth(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  String _localCorrelationCode(
    EmergencySnapshot snapshot,
    DateTime expiresAt,
  ) {
    final seed = snapshot.capturedAt.millisecondsSinceEpoch ^
        snapshot.type.index ^
        expiresAt.millisecondsSinceEpoch;
    return seed.toRadixString(36);
  }
}