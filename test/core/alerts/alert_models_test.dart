import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/core/alerts/alert_models.dart';

void main() {
  final issued = DateTime.utc(2026, 9, 22, 12);
  final updated = DateTime.utc(2026, 9, 22, 12, 30);

  OutdoorAlert buildAlert({DateTime? issuedAt, DateTime? validUntil}) =>
      OutdoorAlert(
        id: 'a-1',
        authority: AlertAuthority.official,
        type: AlertType.storm,
        severity: AlertSeverity.danger,
        confidence: AlertConfidence.confirmed,
        title: 'Aviso meteorológico',
        sourceName: 'AEMET',
        sourceUrl: 'https://www.aemet.es/',
        issuedAt: issuedAt ?? issued,
        updatedAt: updated,
        validUntil: validUntil ?? DateTime.utc(2026, 9, 22, 15),
      );

  test('official alert preserves authority and traceable source', () {
    final alert = buildAlert();
    expect(alert.isOfficial, isTrue);
    expect(alert.hasTraceableSource, isTrue);
  });

  test('expired alert is not valid for current safety decisions', () {
    final alert = buildAlert(validUntil: DateTime.utc(2026, 9, 22, 13));
    expect(alert.isValidAt(DateTime.utc(2026, 9, 22, 13, 1)), isFalse);
  });

  test('future-issued alert is not valid before issuance', () {
    final alert = buildAlert(issuedAt: DateTime.utc(2026, 9, 22, 14));
    expect(alert.isValidAt(DateTime.utc(2026, 9, 22, 13)), isFalse);
  });
}
