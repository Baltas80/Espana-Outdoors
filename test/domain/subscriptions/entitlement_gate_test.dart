import 'package:espana_outdoors/domain/subscriptions/entitlement_gate.dart';
import 'package:espana_outdoors/domain/subscriptions/entitlements.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free keeps safety-critical basic capabilities independent of premium', () {
    const gate = EntitlementGate(OutdoorPlan.free);
    expect(gate.can(OutdoorEntitlement.routeDiscovery), isTrue);
    expect(gate.can(OutdoorEntitlement.gpsRecording), isTrue);
    expect(gate.can(OutdoorEntitlement.trustedContacts), isTrue);
    expect(gate.can(OutdoorEntitlement.advancedOfflineMaps), isFalse);
  });

  test('premium unlocks differentiated outdoor capabilities', () {
    const gate = EntitlementGate(OutdoorPlan.premium);
    expect(gate.can(OutdoorEntitlement.routeSafetyAssessment), isTrue);
    expect(gate.can(OutdoorEntitlement.petMode), isTrue);
    expect(gate.can(OutdoorEntitlement.naturaProtect), isFalse);
  });

  test('professional unlocks operational capabilities', () {
    const gate = EntitlementGate(OutdoorPlan.professional);
    expect(gate.can(OutdoorEntitlement.rescueLink), isTrue);
    expect(gate.can(OutdoorEntitlement.apiAccess), isTrue);
    expect(gate.can(OutdoorEntitlement.prioritySupport), isTrue);
  });
}
