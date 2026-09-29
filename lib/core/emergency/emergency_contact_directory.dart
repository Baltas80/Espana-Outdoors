import 'dart:convert';

import 'package:flutter/services.dart';

final class EmergencyContact {
  const EmergencyContact({
    required this.police,
    required this.ambulance,
    required this.fire,
    required this.general,
  });

  final String police;
  final String ambulance;
  final String fire;
  final String general;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    String read(String key) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      throw const FormatException('Invalid emergency contact entry');
    }

    return EmergencyContact(
      police: read('police'),
      ambulance: read('ambulance'),
      fire: read('fire'),
      general: read('general'),
    );
  }
}

/// Offline emergency-number directory adapted from ly2xxx/sos.
/// The dataset is bundled locally and therefore does not require network access.
final class EmergencyContactDirectory {
  EmergencyContactDirectory._();

  static final EmergencyContactDirectory instance =
      EmergencyContactDirectory._();

  Future<Map<String, EmergencyContact>>? _loadFuture;

  Future<Map<String, EmergencyContact>> load() {
    return _loadFuture ??= _load();
  }

  Future<Map<String, EmergencyContact>> _load() async {
    final raw = await rootBundle.loadString(
      'assets/emergency/emergency_contacts.json',
    );
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Emergency contacts JSON must be an object');
    }

    return <String, EmergencyContact>{
      for (final entry in decoded.entries)
        entry.key: EmergencyContact.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        ),
    };
  }

  Future<EmergencyContact?> forCountry(String country) async {
    final contacts = await load();
    return contacts[country];
  }

  Future<EmergencyContact> spain() async {
    final contact = await forCountry('Spain');
    if (contact == null) {
      throw StateError('Spain is missing from the emergency directory.');
    }
    return contact;
  }
}
