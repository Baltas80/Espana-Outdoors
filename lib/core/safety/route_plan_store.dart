import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'route_plan.dart';

class RoutePlanStore {
  static const _key = 'active_route_plan';

  Future<RoutePlan?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final plan = RoutePlan.fromJson(decoded);
      return plan.isValid ? plan : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> save(RoutePlan plan) async {
    if (!plan.isValid) {
      throw ArgumentError.value(plan, 'plan', 'Plan de ruta inválido.');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(plan.toJson()));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}
