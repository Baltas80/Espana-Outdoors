import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/domain/subscriptions/entitlement_gate.dart';
import 'package:espana_outdoors/domain/subscriptions/entitlements.dart';

void main() {
  test('free exposes only core outdoor capabilities', () {
    const gate = EntitlementGate(OutdoorPlan.free);

    expect(gate.can(OutdoorEntitlement.routeDiscovery), isTrue);
    expect(gate.can(OutdoorEntitlement.gpxImportExport), isTrue);
    expect(gate.can(OutdoorEntitlement.advancedOfflineMaps), isFalse);
    expect(gate.can(OutdoorEntitlement.rescueLink), isFalse);
  });

  test('premium unlocks safety/pet capabilities without professional APIs', () {
    const gate = EntitlementGate(OutdoorPlan.premium);

    expect(gate.can(OutdoorEntitlement.routeSafetyAssessment), isTrue);
    expect(gate.can(OutdoorEntitlement.petMode), isTrue);
    expect(gate.can(OutdoorEntitlement.advancedAlerts), isTrue);
    expect(gate.can(OutdoorEntitlement.professionalData), isFalse);
    expect(gate.can(OutdoorEntitlement.apiAccess), isFalse);
  });

  test('professional includes conservation, rescue and professional access', () {
    const gate = EntitlementGate(OutdoorPlan.professional);

    expect(gate.can(OutdoorEntitlement.naturaProtect), isTrue);
    expect(gate.can(OutdoorEntitlement.rescueLink), isTrue);
    expect(gate.can(OutdoorEntitlement.professionalData), isTrue);
    expect(gate.can(OutdoorEntitlement.apiAccess), isTrue);
  });
}
