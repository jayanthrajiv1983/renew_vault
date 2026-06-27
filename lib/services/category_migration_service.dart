import 'package:flutter/foundation.dart';

import '../constants/categories.dart';
import 'settings_service.dart';
import 'storage_service.dart';

/// One-time migration of legacy category names on stored renewal items.
class CategoryMigrationService {
  CategoryMigrationService._();

  static final CategoryMigrationService instance = CategoryMigrationService._();

  Future<void> runMigrationIfNeeded() async {
    if (SettingsService.instance.isCategoryMigrationV1Complete()) {
      final hasLegacy = StorageService.instance
          .getAll()
          .any((item) => Categories.legacyReplacementFor(item.category) != null);
      if (!hasLegacy) {
        return;
      }
    }

    final items = StorageService.instance.getAll();
    var migratedCount = 0;

    for (final item in items) {
      final replacement = Categories.legacyReplacementFor(item.category);
      if (replacement == null) {
        continue;
      }

      final updated = item.copyWith(category: replacement);
      await StorageService.instance.update(updated);
      migratedCount++;
    }

    await SettingsService.instance.setCategoryMigrationV1Complete(true);

    if (kDebugMode && migratedCount > 0) {
      debugPrint(
        'CategoryMigrationService: migrated $migratedCount renewal item(s)',
      );
    }
  }
}
