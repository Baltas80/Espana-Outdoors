import '../../domain/subscriptions/entitlements.dart';

abstract interface class SubscriptionService {
  Future<void> configure({String? appUserId});
  Future<OutdoorPlan> currentPlan();
  Future<OutdoorPlan> refreshPlan();
  Future<void> identify(String appUserId);
  Future<void> restorePurchases();
}
