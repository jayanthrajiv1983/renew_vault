import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/app_brand.dart';

/// Single source of truth for app version and release channel from [PackageInfo].
class AppInfoService {
  AppInfoService._();

  static final AppInfoService instance = AppInfoService._();

  PackageInfo? _packageInfo;
  Future<PackageInfo>? _loadFuture;

  bool get isLoaded => _packageInfo != null;

  static Future<PackageInfo> getPackageInfo() =>
      instance._ensureLoaded();

  static Future<String> getVersion() async => (await getPackageInfo()).version;

  static Future<String> getBuildNumber() async => (await getPackageInfo()).buildNumber;

  Future<void> init() async {
    try {
      final packageInfo = await _ensureLoaded();
      if (kDebugMode) {
        debugPrint('Package version: ${packageInfo.version}');
        debugPrint('Build number: ${packageInfo.buildNumber}');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AppInfoService.init failed: $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  Future<PackageInfo> _ensureLoaded() {
    return _loadFuture ??= PackageInfo.fromPlatform().then((info) {
      _packageInfo = info;
      return info;
    });
  }

  Future<String> get version async => AppInfoService.getVersion();

  Future<String> get buildNumber async => AppInfoService.getBuildNumber();


  Future<String> get packageName async => (await _ensureLoaded()).packageName;

  String? get versionSync => _packageInfo?.version;

  String? get buildNumberSync => _packageInfo?.buildNumber;

  String? get packageNameSync => _packageInfo?.packageName;

  /// User-facing label for the release channel, e.g. "Beta". Empty when stable.
  String get releaseChannel => AppBrand.isBeta ? 'Beta' : '';

  /// Formats version for About and diagnostics when a build number is present.
  static String formatVersionString({
    required String version,
    required String buildNumber,
  }) {
    final base = 'Version $version';
    if (buildNumber.isNotEmpty && buildNumber != '0') {
      return '$base (Build $buildNumber)';
    }
    return base;
  }

  Future<String> get formattedVersionString async {
    final info = await _ensureLoaded();
    return formatVersionString(
      version: info.version,
      buildNumber: info.buildNumber,
    );
  }

  String? get formattedVersionStringSync {
    final info = _packageInfo;
    if (info == null) {
      return null;
    }
    return formatVersionString(
      version: info.version,
      buildNumber: info.buildNumber,
    );
  }
}
