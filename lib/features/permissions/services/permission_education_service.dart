import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/logging_service.dart';
import '../models/app_permission_type.dart';

/// Tracks which permission education screens have already been shown.
class PermissionEducationService {
  PermissionEducationService._();

  static final PermissionEducationService instance = PermissionEducationService._();

  static const educationShownPrefix = 'permission_education_shown_';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String keyFor(AppPermissionType type) =>
      '$educationShownPrefix${type.name}';

  bool hasShownEducation(AppPermissionType type) {
    return _prefs?.getBool(keyFor(type)) ?? false;
  }

  Future<void> markEducationShown(AppPermissionType type) async {
    await _prefs?.setBool(keyFor(type), true);
    LoggingService.instance.logInfo(
      'PERMISSIONS',
      'Education marked shown for ${type.name}',
    );
  }
}
