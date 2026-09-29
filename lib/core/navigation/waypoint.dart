class OutdoorWaypoint {
  const OutdoorWaypoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.elevationMeters,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double? elevationMeters;
  final String? note;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'elevationMeters': elevationMeters,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory OutdoorWaypoint.fromJson(Map<String, dynamic> json) {
    return OutdoorWaypoint(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      elevationMeters: (json['elevationMeters'] as num?)?.toDouble(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
