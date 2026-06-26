import 'package:hive_flutter/hive_flutter.dart';

import '../models/renewal_item.dart';
import 'notification_service.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const _boxName = 'renewals';

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  List<RenewalItem> getAll() {
    final box = _box;
    if (box == null || box.isEmpty) {
      return [];
    }

    final items = box.values
        .map(
          (value) => RenewalItem.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();

    items.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
    return items;
  }

  Future<void> save(RenewalItem item) async {
    await _box!.put(item.id, item.toJson());
    await NotificationService.instance.scheduleRenewalReminders(item);
  }

  Future<void> update(RenewalItem item) async {
    await save(item);
  }

  Future<RenewalItem?> getById(String id) async {
    final value = _box?.get(id);
    if (value == null) {
      return null;
    }
    return RenewalItem.fromJson(Map<String, dynamic>.from(value as Map));
  }

  Future<void> delete(String id) async {
    await NotificationService.instance.cancelRenewalReminders(id);
    await _box!.delete(id);
  }
}
