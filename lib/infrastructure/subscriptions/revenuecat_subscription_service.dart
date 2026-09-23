import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/contracts/subscription_service.dart';
import '../../domain/subscriptions/entitlements.dart';

/// RevenueCat adapter. Product behaviour remains entitlement-driven and does
/// not depend on store product identifiers scattered through the UI.
final class RevenueCatSubscriptionService implements SubscriptionService {
  RevenueCatSubscriptionService({
    required this.apiKey,
    this.premiumEntitlementId = 'premium',
    this.professionalEntitlementId = 'professional',
  });

  final String apiKey;
  final String premiumEntitlementId;
  final String professionalEntitlementId;

  @override
  Future<void> configure({String? appUserId}) async {
    if (apiKey.isEmpty) {
      throw StateError('RevenueCat API key is not configured.');
    }
    final configuration = PurchasesConfiguration(apiKey)
      ..appUserID = appUserId
      ..diagnosticsEnabled = false;
    await Purchases.configure(configuration);
  }

  @override
  Future<void> identify(String appUserId) async {
    if (appUserId.trim().isEmpty) {
      throw ArgumentError.value(appUserId, 'appUserId');
    }
    await Purchases.logIn(appUserId);
  }

  @override
  Future<OutdoorPlan> currentPlan() async {
    final info = await Purchases.getCustomerInfo();
    return _planFrom(info);
  }

  @override
  Future<OutdoorPlan> refreshPlan() async {
    await Purchases.invalidateCustomerInfoCache();
    return currentPlan();
  }

  @override
  Future<void> restorePurchases() async {
    await Purchases.restorePurchases();
  }

  OutdoorPlan _planFrom(CustomerInfo info) {
    final active = info.entitlements.active;
    if (active.containsKey(professionalEntitlementId)) {
      return OutdoorPlan.professional;
    }
    if (active.containsKey(premiumEntitlementId)) {
      return OutdoorPlan.premium;
    }
    return OutdoorPlan.free;
  }
}
