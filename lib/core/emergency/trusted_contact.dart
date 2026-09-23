import '../domain/outdoor_models.dart';

class TrustedContact {
  const TrustedContact({
    required this.id,
    required this.displayName,
    required this.phone,
    this.email,
    this.enabled = true,
  });

  final String id;
  final String displayName;
  final String phone;
  final String? email;
  final bool enabled;

  Map<String, Object?> toJson() => {
        'id': id,
        'displayName': displayName,
        'phone': phone,
        'email': email,
        'enabled': enabled,
      };

  factory TrustedContact.fromJson(Map<dynamic, dynamic> json) {
    return TrustedContact(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      enabled: json['enabled'] != false,
    );
  }
}

class EmergencySharePayload {
  const EmergencySharePayload({
    required this.snapshot,
    required this.expiresAt,
    required this.shareToken,
  });

  final EmergencySnapshot snapshot;
  final DateTime expiresAt;
  final String shareToken;

  bool get expired => !DateTime.now().toUtc().isBefore(expiresAt);
}