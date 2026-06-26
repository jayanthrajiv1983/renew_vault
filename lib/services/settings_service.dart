import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';



import '../models/renewal_item.dart';

import '../models/sort_option.dart';

import '../providers/theme_provider.dart';



class SettingsService extends ChangeNotifier {

  SettingsService._();



  static final SettingsService instance = SettingsService._();



  static const _boxName = 'settings';



  static const sortOptionKey = 'sortOption';

  static const defaultReminderDaysKey = 'defaultReminderDays';

  static const enableNotificationsKey = 'enableNotifications';

  static const showExpiredBannerKey = 'showExpiredBanner';

  static const autoSortByNearestExpiryKey = 'autoSortByNearestExpiry';



  Box? _box;



  Future<void> init() async {

    _box = await Hive.openBox(_boxName);

  }



  Map<String, dynamic> getAll() {

    final box = _box;

    if (box == null || box.isEmpty) {

      return {};

    }



    return Map<String, dynamic>.from(box.toMap());

  }



  AppThemeMode getThemeMode() => ThemeProvider.instance.appThemeMode;



  Future<void> setThemeMode(AppThemeMode mode) =>

      ThemeProvider.instance.setThemeMode(mode);



  List<int> getDefaultReminderDays() {

    final value = _box?.get(defaultReminderDaysKey);

    if (value is List) {

      return value.whereType<int>().toList();

    }

    return List<int>.from(RenewalItem.defaultReminderDays);

  }



  Future<void> setDefaultReminderDays(List<int> days) async {

    await _box?.put(defaultReminderDaysKey, days);

    notifyListeners();

  }



  bool getEnableNotifications() {

    final value = _box?.get(enableNotificationsKey);

    if (value is bool) {

      return value;

    }

    return true;

  }



  Future<void> setEnableNotifications(bool enabled) async {

    await _box?.put(enableNotificationsKey, enabled);

    notifyListeners();

  }



  bool getShowExpiredBanner() {

    final value = _box?.get(showExpiredBannerKey);

    if (value is bool) {

      return value;

    }

    return true;

  }



  Future<void> setShowExpiredBanner(bool show) async {

    await _box?.put(showExpiredBannerKey, show);

    notifyListeners();

  }



  bool getAutoSortByNearestExpiry() {

    final value = _box?.get(autoSortByNearestExpiryKey);

    if (value is bool) {

      return value;

    }

    return false;

  }



  Future<void> setAutoSortByNearestExpiry(bool enabled) async {

    await _box?.put(autoSortByNearestExpiryKey, enabled);

    notifyListeners();

  }



  SortOption? getSortOption() {

    final value = _box?.get(sortOptionKey);

    if (value is! String) {

      return null;

    }



    for (final option in SortOption.values) {

      if (option.name == value) {

        return option;

      }

    }

    return null;

  }



  Future<void> setSortOption(SortOption? option) async {

    if (option == null) {

      await _box?.delete(sortOptionKey);

    } else {

      await _box?.put(sortOptionKey, option.name);

    }

    notifyListeners();

  }



  SortOption? getEffectiveSortOption() {

    final saved = getSortOption();

    if (saved != null) {

      return saved;

    }

    if (getAutoSortByNearestExpiry()) {

      return SortOption.nearestExpiry;

    }

    return null;

  }



  Future<void> applySettings(Map<String, dynamic> settings) async {

    await _box?.clear();

    for (final entry in settings.entries) {

      await _box?.put(entry.key, entry.value);

    }

    ThemeProvider.instance.reload();

    notifyListeners();

  }

}


