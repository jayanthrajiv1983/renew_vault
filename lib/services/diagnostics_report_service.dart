import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../providers/theme_provider.dart';
import 'app_info_service.dart';
import 'attachment_service.dart';
import 'family_service.dart';
import 'hive_encryption_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';
import '../theme/app_brand.dart';
import '../utils/format_helpers.dart';

class DiagnosticsReportData {
  const DiagnosticsReportData({
    required this.appVersion,
    required this.buildNumber,
    required this.releaseChannel,
    required this.packageName,
    required this.buildMode,
    required this.platform,
    required this.osVersion,
    required this.manufacturer,
    required this.deviceModel,
    required this.darkModeEnabled,
    required this.appLockEnabled,
    required this.notificationsEnabled,
    required this.lastBackupDate,
    required this.totalRenewals,
    required this.totalFamilyMembers,
    required this.totalAttachments,
    required this.databaseSizeBytes,
    required this.attachmentsSizeBytes,
    required this.totalStorageBytes,
  });

  final String appVersion;
  final String buildNumber;
  final String releaseChannel;
  final String packageName;
  final String buildMode;
  final String platform;
  final String osVersion;
  final String manufacturer;
  final String deviceModel;
  final bool darkModeEnabled;
  final bool appLockEnabled;
  final bool notificationsEnabled;
  final String lastBackupDate;
  final int totalRenewals;
  final int totalFamilyMembers;
  final int totalAttachments;
  final int databaseSizeBytes;
  final int attachmentsSizeBytes;
  final int totalStorageBytes;
}

/// Collects app/device diagnostics and builds shareable report text.
class DiagnosticsReportService {
  DiagnosticsReportService._();

  static final DiagnosticsReportService instance = DiagnosticsReportService._();

  Future<DiagnosticsReportData> collect() async {
    final appInfo = AppInfoService.instance;
    await appInfo.init();
    final deviceInfo = await _getExtendedDeviceInfo();
    final settings = SettingsService.instance;

    final lastBackup = settings.getLastBackupAt();
    final renewals = StorageService.instance.getAll();
    final attachmentCount = renewals.fold<int>(
      0,
      (sum, item) => sum + item.attachments.length,
    );

    final storageSizes = await _calculateStorageSizes();

    final themeMode = ThemeProvider.instance.appThemeMode;
    final darkModeEnabled = themeMode == AppThemeMode.dark ||
        (themeMode == AppThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    return DiagnosticsReportData(
      appVersion: appInfo.versionSync ?? 'Unknown',
      buildNumber: appInfo.buildNumberSync ?? 'Unknown',
      releaseChannel: appInfo.releaseChannel.isEmpty
          ? 'Stable'
          : appInfo.releaseChannel,
      packageName: appInfo.packageNameSync ?? 'Unknown',
      buildMode: kDebugMode ? 'Debug' : 'Release',
      platform: deviceInfo.platform,
      osVersion: deviceInfo.osVersion,
      manufacturer: deviceInfo.manufacturer,
      deviceModel: deviceInfo.deviceModel,
      darkModeEnabled: darkModeEnabled,
      appLockEnabled: settings.getAppLockEnabled(),
      notificationsEnabled: settings.getEnableNotifications(),
      lastBackupDate: lastBackup == null
          ? 'Never'
          : formatBackupDateTime(lastBackup),
      totalRenewals: renewals.length,
      totalFamilyMembers: FamilyService.instance.getAll().length,
      totalAttachments: attachmentCount,
      databaseSizeBytes: storageSizes.databaseBytes,
      attachmentsSizeBytes: storageSizes.attachmentsBytes,
      totalStorageBytes: storageSizes.totalBytes,
    );
  }

  String buildReportText(DiagnosticsReportData data) {
    String enabledDisabled(bool value) => value ? 'Enabled' : 'Disabled';

    final buffer = StringBuffer()
      ..writeln('${AppBrand.name} Diagnostics')
      ..writeln()
      ..writeln(AppInfoService.formatVersionString(
        version: data.appVersion,
        buildNumber: data.buildNumber,
      ))
      ..writeln('Release Channel: ${data.releaseChannel}')
      ..writeln('Package Name: ${data.packageName}')
      ..writeln('Build Mode: ${data.buildMode}')
      ..writeln()
      ..writeln('Platform: ${data.platform}')
      ..writeln('OS Version: ${data.osVersion}')
      ..writeln('Device Manufacturer: ${data.manufacturer}')
      ..writeln('Device Model: ${data.deviceModel}')
      ..writeln()
      ..writeln('Dark Mode: ${enabledDisabled(data.darkModeEnabled)}')
      ..writeln('App Lock: ${enabledDisabled(data.appLockEnabled)}')
      ..writeln(
        'Notifications: ${enabledDisabled(data.notificationsEnabled)}',
      )
      ..writeln('Last Backup: ${data.lastBackupDate}')
      ..writeln('Renewals: ${data.totalRenewals}')
      ..writeln('Family Members: ${data.totalFamilyMembers}')
      ..writeln('Attachments: ${data.totalAttachments}')
      ..writeln()
      ..writeln('Database Size: ${formatFileSize(data.databaseSizeBytes)}')
      ..writeln(
        'Attachments Size: ${formatFileSize(data.attachmentsSizeBytes)}',
      )
      ..writeln(
        'Total App Storage Used: ${formatFileSize(data.totalStorageBytes)}',
      );

    return buffer.toString().trimRight();
  }

  Future<String> collectReportText() async {
    final data = await collect();
    return buildReportText(data);
  }

  Future<
      ({
        String platform,
        String osVersion,
        String manufacturer,
        String deviceModel,
      })> _getExtendedDeviceInfo() async {
    if (kIsWeb) {
      return (
        platform: 'Web',
        osVersion: 'N/A',
        manufacturer: 'N/A',
        deviceModel: 'N/A',
      );
    }

    final plugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return (
        platform: 'Android',
        osVersion: '${info.version.release} (SDK ${info.version.sdkInt})',
        manufacturer: info.manufacturer,
        deviceModel: info.model,
      );
    }
    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return (
        platform: 'iOS',
        osVersion: info.systemVersion,
        manufacturer: 'Apple',
        deviceModel: info.utsname.machine,
      );
    }
    if (Platform.isWindows) {
      final info = await plugin.windowsInfo;
      return (
        platform: 'Windows',
        osVersion:
            '${info.majorVersion}.${info.minorVersion}.${info.buildNumber}',
        manufacturer: info.computerName,
        deviceModel: info.productName,
      );
    }
    if (Platform.isMacOS) {
      final info = await plugin.macOsInfo;
      return (
        platform: 'macOS',
        osVersion:
            '${info.majorVersion}.${info.minorVersion}.${info.patchVersion}',
        manufacturer: 'Apple',
        deviceModel: info.model,
      );
    }
    if (Platform.isLinux) {
      final info = await plugin.linuxInfo;
      return (
        platform: 'Linux',
        osVersion: info.prettyName,
        manufacturer: info.name,
        deviceModel: info.machineId ?? 'Unknown',
      );
    }

    return (
      platform: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      manufacturer: 'Unknown',
      deviceModel: 'Unknown',
    );
  }

  Future<
      ({
        int databaseBytes,
        int attachmentsBytes,
        int totalBytes,
      })> _calculateStorageSizes() async {
    if (kIsWeb) {
      return (databaseBytes: 0, attachmentsBytes: 0, totalBytes: 0);
    }

    final documentsDir = await getApplicationDocumentsDirectory();

    var databaseBytes = 0;
    for (final boxName in HiveEncryptionService.encryptedBoxNames) {
      databaseBytes += await _fileSizeIfExists(
        File(p.join(documentsDir.path, '$boxName.hive')),
      );
      databaseBytes += await _fileSizeIfExists(
        File(p.join(documentsDir.path, '$boxName.lock')),
      );
    }

    final attachmentsDir =
        await AttachmentService.instance.getAttachmentsRootDirectory();
    final attachmentsBytes = await _directorySize(attachmentsDir);

    final totalBytes = await _directorySize(documentsDir);

    return (
      databaseBytes: databaseBytes,
      attachmentsBytes: attachmentsBytes,
      totalBytes: totalBytes,
    );
  }

  Future<int> _fileSizeIfExists(File file) async {
    if (!await file.exists()) {
      return 0;
    }
    return file.length();
  }

  Future<int> _directorySize(Directory directory) async {
    if (!await directory.exists()) {
      return 0;
    }

    var total = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
