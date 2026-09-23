import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../lib/alert_catalog.dart';

void main() {
  test('filters expired and distant alerts', () async {
    final directory = await Directory.systemTemp.createTemp('espana-alerts-');
    addTearDown(() => directory.delete(recursive: true));

    final now = DateTime.utc(2026, 1, 10, 12);
    final file = File('${directory.path}/alerts.json');
    await file.writeAsString(
      jsonEncode({
        'alerts': [
          {
            'id': 'near',
            'authority': 'official',
            'type': 'wildfire',
            'severity': 'danger',
            'confidence': 'confirmed',
            'title': 'Incendio activo',
            'sourceName': 'Fuente oficial',
            'sourceUrl': 'https://example.invalid/source',
            'issuedAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
            'updatedAt': now.subtract(const Duration(minutes: 5)).toIso8601String(),
            'validUntil': now.add(const Duration(hours: 2)).toIso8601String(),
            'latitude': 40.0,
            'longitude': -3.0,
            'radiusKm': 10,
          },
          {
            'id': 'far',
            'authority': 'official',
            'type': 'storm',
            'severity': 'caution',
            'confidence': 'confirmed',
            'title': 'Tormenta lejana',
            'sourceName': 'Fuente oficial',
            'sourceUrl': 'https://example.invalid/source',
            'issuedAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
            'updatedAt': now.subtract(const Duration(minutes: 5)).toIso8601String(),
            'validUntil': now.add(const Duration(hours: 2)).toIso8601String(),
            'latitude': 41.0,
            'longitude': -4.0,
            'radiusKm': 10,
          },
          {
            'id': 'expired',
            'authority': 'official',
            'type': 'flood',
            'severity': 'danger',
            'confidence': 'confirmed',
            'title': 'Aviso caducado',
            'sourceName': 'Fuente oficial',
            'sourceUrl': 'https://example.invalid/source',
            'issuedAt': now.subtract(const Duration(hours: 4)).toIso8601String(),
            'updatedAt': now.subtract(const Duration(hours: 3)).toIso8601String(),
            'validUntil': now.subtract(const Duration(minutes: 1)).toIso8601String(),
            'latitude': 40.0,
            'longitude': -3.0,
            'radiusKm': 10,
          },
        ],
      }),
    );

    final catalog = AlertCatalog(path: file.path);
    final alerts = await catalog.nearby(
      latitude: 40.0,
      longitude: -3.0,
      radiusKm: 25,
      now: now,
    );

    expect(alerts.map((alert) => alert.id), contains('near'));
    expect(alerts.map((alert) => alert.id), isNot(contains('far')));
    expect(alerts.map((alert) => alert.id), isNot(contains('expired')));
  });

  test('accepts region-wide alerts without coordinates', () {
    final alert = AlertCatalogItem.fromJson({
      'id': 'region',
      'authority': 'official',
      'type': 'heat',
      'severity': 'caution',
      'confidence': 'probable',
      'title': 'Aviso regional',
      'sourceName': 'Fuente oficial',
      'sourceUrl': 'https://example.invalid/source',
      'issuedAt': '2026-01-10T10:00:00Z',
      'updatedAt': '2026-01-10T11:00:00Z',
      'validUntil': '2026-01-10T15:00:00Z',
    });

    expect(alert.id, 'region');
    expect(alert.latitude, isNull);
    expect(alert.longitude, isNull);
  });

  test('rejects invalid source urls and partial coordinates', () {
    expect(
      () => AlertCatalogItem.fromJson({
        'id': 'bad-url',
        'authority': 'official',
        'type': 'other',
        'severity': 'information',
        'confidence': 'unknown',
        'title': 'Bad',
        'sourceName': 'Fuente',
        'sourceUrl': 'not-a-url',
        'issuedAt': '2026-01-10T10:00:00Z',
        'updatedAt': '2026-01-10T11:00:00Z',
        'validUntil': '2026-01-10T15:00:00Z',
      }),
      throwsFormatException,
    );

    expect(
      () => AlertCatalogItem.fromJson({
        'id': 'partial',
        'authority': 'official',
        'type': 'other',
        'severity': 'information',
        'confidence': 'unknown',
        'title': 'Partial',
        'sourceName': 'Fuente',
        'sourceUrl': 'https://example.invalid/source',
        'issuedAt': '2026-01-10T10:00:00Z',
        'updatedAt': '2026-01-10T11:00:00Z',
        'validUntil': '2026-01-10T15:00:00Z',
        'latitude': 40.0,
      }),
      throwsFormatException,
    );
  });
}
