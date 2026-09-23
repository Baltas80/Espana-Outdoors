import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

class AlertCatalogItem {
  const AlertCatalogItem({
    required this.id,
    required this.authority,
    required this.type,
    required this.severity,
    required this.confidence,
    required this.title,
    required this.sourceName,
    required this.sourceUrl,
    required this.issuedAt,
    required this.updatedAt,
    required this.validUntil,
    this.description,
    this.regionId,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });

  final String id;
  final String authority;
  final String type;
  final String severity;
  final String confidence;
  final String title;
  final String sourceName;
  final String sourceUrl;
  final DateTime issuedAt;
  final DateTime updatedAt;
  final DateTime validUntil;
  final String? description;
  final String? regionId;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;

  bool isValidAt(DateTime now) =>
      !issuedAt.isAfter(now) &&
      !updatedAt.isAfter(now) &&
      validUntil.isAfter(now);

  Map<String, dynamic> toJson() => {
        'id': id,
        'authority': authority,
        'type': type,
        'severity': severity,
        'confidence': confidence,
        'title': title,
        if (description != null) 'description': description,
        'sourceName': sourceName,
        'sourceUrl': sourceUrl,
        'issuedAt': issuedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'validUntil': validUntil.toIso8601String(),
        if (regionId != null) 'regionId': regionId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radiusKm != null) 'radiusKm': radiusKm,
      };

  factory AlertCatalogItem.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isEmpty) throw FormatException('Missing $key');
      return value;
    }

    final issuedAt = DateTime.tryParse('${json['issuedAt'] ?? ''}');
    final updatedAt = DateTime.tryParse('${json['updatedAt'] ?? ''}');
    final validUntil = DateTime.tryParse('${json['validUntil'] ?? ''}');
    if (issuedAt == null || updatedAt == null || validUntil == null) {
      throw const FormatException('Invalid alert timestamps');
    }

    final authority = requiredString('authority');
    if (authority != 'official' && authority != 'espanaOutdoor') {
      throw const FormatException('Invalid alert authority');
    }

    final sourceUrl = requiredString('sourceUrl');
    final parsedUrl = Uri.tryParse(sourceUrl);
    if (parsedUrl == null ||
        !parsedUrl.hasScheme ||
        (parsedUrl.scheme != 'https' && parsedUrl.scheme != 'http')) {
      throw const FormatException('Invalid sourceUrl');
    }

    final latitude = _number(json['latitude']);
    final longitude = _number(json['longitude']);
    final radiusKm = _number(json['radiusKm']);

    if ((latitude == null) != (longitude == null)) {
      throw const FormatException('latitude/longitude must be paired');
    }
    if (latitude != null &&
        (latitude < -90 || latitude > 90 ||
            longitude! < -180 || longitude > 180)) {
      throw const FormatException('Invalid alert coordinates');
    }
    if (radiusKm != null && radiusKm <= 0) {
      throw const FormatException('Invalid alert radius');
    }

    return AlertCatalogItem(
      id: requiredString('id'),
      authority: authority,
      type: requiredString('type'),
      severity: requiredString('severity'),
      confidence: requiredString('confidence'),
      title: requiredString('title'),
      description: json['description']?.toString(),
      sourceName: requiredString('sourceName'),
      sourceUrl: sourceUrl,
      issuedAt: issuedAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
      validUntil: validUntil.toUtc(),
      regionId: json['regionId']?.toString(),
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    return value == null ? null : double.tryParse('$value');
  }
}

class AlertCatalog {
  AlertCatalog({this.path});

  final String? path;
  DateTime? _loadedModified;
  List<AlertCatalogItem> _items = const [];

  Future<List<AlertCatalogItem>> nearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required DateTime now,
  }) async {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(longitude, 'longitude');
    }
    if (radiusKm < 0) {
      throw ArgumentError.value(radiusKm, 'radiusKm');
    }

    await _refreshIfNeeded();

    return _items
        .where((item) => item.isValidAt(now))
        .where((item) {
          if (item.latitude == null || item.longitude == null) return true;
          return _distanceKm(
                latitude,
                longitude,
                item.latitude!,
                item.longitude!,
              ) <=
              (item.radiusKm ?? radiusKm);
        })
        .toList(growable: false);
  }

  Future<void> _refreshIfNeeded() async {
    final filePath = path;
    if (filePath == null || filePath.trim().isEmpty) {
      _items = const [];
      _loadedModified = null;
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      _items = const [];
      _loadedModified = null;
      return;
    }

    final modified = await file.lastModified();
    if (_loadedModified == modified) return;

    final decoded = jsonDecode(await file.readAsString());
    final rawItems = decoded is List
        ? decoded
        : decoded is Map<String, dynamic>
            ? decoded['alerts']
            : null;
    if (rawItems is! List) {
      throw const FormatException('Alert catalog must contain an alerts list');
    }

    _items = rawItems
        .whereType<Map>()
        .map(
          (item) => AlertCatalogItem.fromJson(
            item.map((key, value) => MapEntry('$key', value)),
          ),
        )
        .toList(growable: false);
    _loadedModified = modified;
  }

  double _distanceKm(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    const earthRadiusKm = 6371.0088;
    double radians(double value) => value * math.pi / 180;
    final dLat = radians(latitudeB - latitudeA);
    final dLon = radians(longitudeB - longitudeA);
    final latA = radians(latitudeA);
    final latB = radians(latitudeB);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(latA) *
            math.cos(latB) *
            math.pow(math.sin(dLon / 2), 2);
    final safeH = h.clamp(0, 1).toDouble();
    return earthRadiusKm *
        2 *
        math.atan2(math.sqrt(safeH), math.sqrt(1 - safeH));
  }
}
