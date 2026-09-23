import 'subscriptions/entitlements.dart';

/// Single capability gate for product code. Billing providers only resolve
/// entitlements; they do not get to decide product behaviour directly.
final class EntitlementGate {
  const EntitlementGate(this.plan);

  final OutdoorPlan plan;

  bool can(OutdoorEntitlement entitlement) =>
      EntitlementCatalog.allows(plan, entitlement);

  void require(OutdoorEntitlement entitlement) {
    if (!can(entitlement)) {
      throw EntitlementRequiredException(entitlement);
    }
  }
}

final class EntitlementRequiredException implements Exception {
  const EntitlementRequiredException(this.entitlement);
  final OutdoorEntitlement entitlement;

  @override
  String toString() => 'Entitlement required: $entitlement';
}
