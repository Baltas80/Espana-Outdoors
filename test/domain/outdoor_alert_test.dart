import 'package:flutter_test/flutter_test.dart';

import '../../lib/domain/alerts/outdoor_alert.dart';

void main() {
  test('alert remains valid until its validity boundary', () {
    final issued = DateTime.utc(2026, 1, 1, 10);
    final alert = OutdoorAlert(
      id: 'a1',
      title: 'Aviso',
      level: OutdoorAlertLevel.precaution,
      origin: OutdoorAlertOrigin.official,
      sourceName: 'Fuente oficial',
      sourceUrl: 'https://example.invalid',
      issuedAt: issued,
      validUntil: issued.add(const Duration(hours: 2)),
    );

    expect(alert.isValidAt(issued.add(const Duration(hours: 1))), isTrue);
    expect(alert.isValidAt(issued.add(const Duration(hours: 2))), isFalse);
  });
}
