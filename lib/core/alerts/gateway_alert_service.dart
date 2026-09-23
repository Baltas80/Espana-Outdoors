import '../live_data/live_data_gateway_client.dart';
import '../live_data/live_data_models.dart';
import 'alert_service.dart';
import 'alert_models.dart';

class GatewayAlertService implements AlertService {
  const GatewayAlertService(this._gateway);

  final LiveDataGateway _gateway;

  @override
  Future<List<OutdoorAlert>> alertsForRegion({
    required String regionId,
    required DateTime now,
  }) async {
    if (regionId.trim().isEmpty) {
      throw ArgumentError.value(regionId, 'regionId');
    }
    return _fetch(
      now: now,
      latitude: 0,
      longitude: 0,
      radiusKm: 500,
      regionId: regionId,
    );
  }

  @override
  Future<List<OutdoorAlert>> alertsForPoint({
    required double latitude,
    required double longitude,
    required DateTime now,
  }) async {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(longitude, 'longitude');
    }

    return _fetch(
      now: now,
      latitude: latitude,
      longitude: longitude,
      radiusKm: 25,
    );
  }

  Future<List<OutdoorAlert>> _fetch({
    required DateTime now,
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? regionId,
  }) async {
    final envelope = await _gateway.get<dynamic>(
      '/v1/alerts',
      {
        'lat': '$latitude',
        'lon': '$longitude',
        'radiusKm': '$radiusKm',
      },
    );

    final raw = envelope.data;
    if (raw is! Map) {
      throw const LiveDataGatewayException('Respuesta de alertas inválida.');
    }

    final rawAlerts = raw['alerts'];
    if (rawAlerts is! List) {
      throw const LiveDataGatewayException('Respuesta sin lista de alertas.');
    }

    return rawAlerts
        .whereType<Map>()
        .map(
          (item) => _parseAlert(
            item.map((key, value) => MapEntry('$key', value)),
          ),
        )
        .whereType<OutdoorAlert>()
        .where((alert) => regionId == null || alert.regionId == regionId)
        .where((alert) => alert.isValidAt(now))
        .toList(growable: false);
  }

  OutdoorAlert? _parseAlert(Map<String, dynamic> json) {
    final issuedAt = DateTime.tryParse('${json['issuedAt'] ?? ''}');
    final updatedAt = DateTime.tryParse('${json['updatedAt'] ?? ''}');
    final validUntil = DateTime.tryParse('${json['validUntil'] ?? ''}');
    if (issuedAt == null || updatedAt == null || validUntil == null) {
      return null;
    }

    final sourceUrl = '${json['sourceUrl'] ?? ''}';
    if (Uri.tryParse(sourceUrl)?.hasScheme != true) return null;

    final id = '${json['id'] ?? ''}'.trim();
    final title = '${json['title'] ?? ''}'.trim();
    final sourceName = '${json['sourceName'] ?? ''}'.trim();
    if (id.isEmpty || title.isEmpty || sourceName.isEmpty) return null;

    return OutdoorAlert(
      id: id,
      authority: _authority(json['authority']),
      type: _type(json['type']),
      severity: _severity(json['severity']),
      confidence: _confidence(json['confidence']),
      title: title,
      description: json['description']?.toString(),
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      issuedAt: issuedAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
      validUntil: validUntil.toUtc(),
      regionId: json['regionId']?.toString(),
    );
  }

  AlertAuthority _authority(Object? value) => switch ('$value') {
        'official' => AlertAuthority.official,
        _ => AlertAuthority.espanaOutdoor,
      };

  AlertType _type(Object? value) {
    const map = {
      'wildfire': AlertType.wildfire,
      'flood': AlertType.flood,
      'storm': AlertType.storm,
      'wind': AlertType.wind,
      'snow': AlertType.snow,
      'heat': AlertType.heat,
      'cold': AlertType.cold,
      'earthquake': AlertType.earthquake,
      'tsunami': AlertType.tsunami,
      'volcano': AlertType.volcano,
      'landslide': AlertType.landslide,
      'closure': AlertType.closure,
      'other': AlertType.other,
    };
    return map['$value'] ?? AlertType.other;
  }

  AlertSeverity _severity(Object? value) {
    const map = {
      'information': AlertSeverity.information,
      'caution': AlertSeverity.caution,
      'danger': AlertSeverity.danger,
      'emergency': AlertSeverity.emergency,
    };
    return map['$value'] ?? AlertSeverity.information;
  }

  AlertConfidence _confidence(Object? value) {
    const map = {
      'confirmed': AlertConfidence.confirmed,
      'probable': AlertConfidence.probable,
      'preliminary': AlertConfidence.preliminary,
      'unknown': AlertConfidence.unknown,
    };
    return map['$value'] ?? AlertConfidence.unknown;
  }
}
