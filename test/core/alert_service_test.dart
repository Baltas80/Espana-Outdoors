import 'package:espana_outdoors/core/alerts/alert_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final issued = DateTime.utc(2026, 9, 23, 8);

  test('explicit expiry takes precedence over age', () {
    final alert = OutdoorAlert(
      id: 'a-1',
      authority: AlertAuthority.official,
      severity: AlertSeverity.warning,
      title: 'Aviso',
      source: 'AEMET',
      issuedAt: issued,
      expiresAt: issued.add(const Duration(hours: 1)),
    );

    expect(
      alert.freshnessAt(issued.add(const Duration(hours: 2))),
      AlertFreshness.expired,
    );
  });

  test('alerts without expiry become stale after conservative TTL', () {
    final alert = OutdoorAlert(
      id: 'a-2',
      authority: AlertAuthority.official,
      severity: AlertSeverity.caution,
      title: 'Aviso',
      source: 'AEMET',
      issuedAt: issued,
    );

    expect(
      alert.freshnessAt(issued.add(const Duration(hours: 7))),
      AlertFreshness.stale,
    );
  });

  test('future timestamps do not become current by accident', () {
    final alert = OutdoorAlert(
      id: 'a-3',
      authority: AlertAuthority.espanaOutdoor,
      severity: AlertSeverity.information,
      title: 'Aviso',
      source: 'España Outdoor',
      issuedAt: issued.add(const Duration(hours: 1)),
    );

    expect(alert.freshnessAt(issued), AlertFreshness.unknown);
  });
}
