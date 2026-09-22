import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'trusted_contact.dart';

class TrustedContactStore {
  TrustedContactStore({Box<Map<dynamic, dynamic>>? box})
      : _box = box ?? Hive.box<Map<dynamic, dynamic>>('route_records');

  static const _key = 'trusted_contacts';
  final Box<Map<dynamic, dynamic>> _box;

  List<TrustedContact> load() {
    final record = _box.get(_key);
    if (record == null) return const [];
    final raw = record['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(TrustedContact.fromJson)
        .where((contact) => contact.id.isNotEmpty && contact.phone.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> save(List<TrustedContact> contacts) async {
    await _box.put(_key, {
      'items': contacts.map((contact) => contact.toJson()).toList(growable: false),
    });
  }
}
