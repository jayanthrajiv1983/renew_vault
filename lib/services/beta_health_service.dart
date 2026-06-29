import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../core/services/logging_service.dart';
import 'hive_encryption_service.dart';

enum BetaTestResult { notTested, pass, fail }

enum BetaTestCategory {
  notifications,
  biometrics,
  ocr,
  backup;

  String get label {
    switch (this) {
      case BetaTestCategory.notifications:
        return 'Notifications';
      case BetaTestCategory.biometrics:
        return 'Biometrics';
      case BetaTestCategory.ocr:
        return 'OCR';
      case BetaTestCategory.backup:
        return 'Backup';
    }
  }
}

class BetaHealthService extends ChangeNotifier {
  BetaHealthService._();

  static final BetaHealthService instance = BetaHealthService._();

  static const _boxName = 'settings';
  static const _resultsKey = 'betaHealthResults';

  Box? _box;

  Box? get _settingsBox {
    if (_box != null) {
      return _box;
    }
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return null;
  }

  Future<void> init() async {
    _box = await HiveEncryptionService.instance.openBox(_boxName);
  }

  Map<BetaTestCategory, BetaTestResult> getAllResults() {
    final raw = _settingsBox?.get(_resultsKey);
    if (raw is! Map) {
      return {
        for (final category in BetaTestCategory.values)
          category: BetaTestResult.notTested,
      };
    }

    final stored = Map<String, dynamic>.from(raw);
    return {
      for (final category in BetaTestCategory.values)
        category: _parseResult(stored[category.name]),
    };
  }

  BetaTestResult getResult(BetaTestCategory category) {
    return getAllResults()[category] ?? BetaTestResult.notTested;
  }

  Future<void> setResult(
    BetaTestCategory category,
    BetaTestResult result,
  ) async {
    final box = _settingsBox ??
        await HiveEncryptionService.instance.openBox(_boxName);
    _box ??= box;

    final current = Map<String, String>.from(
      (box.get(_resultsKey) as Map?)?.cast<String, String>() ?? {},
    );
    current[category.name] = result.name;
    await box.put(_resultsKey, current);

    LoggingService.instance.logInfo(
      'BETA_TOOLS',
      'Health check updated: ${category.label} ${_resultLabel(result)}',
    );
    notifyListeners();
  }

  Future<void> resetAll() async {
    final box = _settingsBox ??
        await HiveEncryptionService.instance.openBox(_boxName);
    _box ??= box;
    await box.delete(_resultsKey);
    notifyListeners();
  }

  BetaTestResult _parseResult(dynamic value) {
    if (value is! String) {
      return BetaTestResult.notTested;
    }
    for (final result in BetaTestResult.values) {
      if (result.name == value) {
        return result;
      }
    }
    return BetaTestResult.notTested;
  }

  String _resultLabel(BetaTestResult result) {
    switch (result) {
      case BetaTestResult.pass:
        return 'PASS';
      case BetaTestResult.fail:
        return 'FAIL';
      case BetaTestResult.notTested:
        return 'NOT TESTED';
    }
  }
}
