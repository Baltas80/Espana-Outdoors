import 'package:espana_outdoors/core/alerts/alert_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('official alert requires provenance and fresh validity', () {
    final now = DateTime.now().toUtc();
    final alert = OutdoorAlert(
      id: 'a-1',
      origin: AlertOrigin.official,
      type: AlertType.storm,
      title: 'Tormenta',
      severity: AlertSeverity.severe,
      confidence: AlertConfidence.high,
      source: 'AEMET',
      publishedAt: now.subtract(const Duration(minutes: 10)),
      updatedAt: now,
      validUntil: now.add(const Duration(hours: 1)),
      sourceUrl: 'https://example.invalid/alert/a-1',
    );

    expect(alert.hasProvenance, isTrue);
    expect(alert.isExpired, isFalse);
    expect(alert.isUsable, isTrue);
  });

  test('expired alert is not usable', () {
    final now = DateTime.now().toUtc();
    final alert = OutdoorAlert(
      id: 'a-2',
      origin: AlertOrigin.official,
      type: AlertType.flood,
      title: 'Inundación',
      severity: AlertSeverity.moderate,
      confidence: AlertConfidence.medium,
      source: 'Protección Civil',
      publishedAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(hours: 1)),
      validUntil: now.subtract(const Duration(minutes: 1)),
    );

    expect(alert.isExpired, isTrue);
    expect(alert.isUsable, isFalse);
  });
}
