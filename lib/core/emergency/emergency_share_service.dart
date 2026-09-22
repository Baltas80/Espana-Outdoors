import 'dart:math';

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

    final expiresAt = DateTime.now().add(ttl);
    return EmergencySharePayload(
      snapshot: snapshot,
      expiresAt: expiresAt,
      shareToken: _token(),
    );
  }

  Future<void> copyShareText(EmergencySharePayload payload) async {
    await Clipboard.setData(ClipboardData(text: _message(payload)));
  }

  Future<bool> openSms(EmergencySharePayload payload, String phone) async {
    if (payload.expired || phone.trim().isEmpty) return false;
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': _message(payload)},
    );
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  String _message(EmergencySharePayload payload) {
    final p = payload.snapshot.position;
    return 'ALERTA España Outdoor. Posición: \${p.latitude.toStringAsFixed(6)}, '
        '\${p.longitude.toStringAsFixed(6)}. Precisión aproximada: '
        '\${payload.snapshot.accuracyMeters.toStringAsFixed(0)} m. '
        'Tipo: \${payload.snapshot.type.name}. '
        'Válida hasta \${payload.expiresAt.toLocal().toIso8601String()}. '
        'Código: \${payload.shareToken}';
  }

  String _token() {
    final random = Random.secure();
    return List.generate(
      12,
      (_) => random.nextInt(36).toRadixString(36),
    ).join();
  }
}
