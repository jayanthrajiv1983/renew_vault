import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../providers/theme_provider.dart';
import '../../../services/attachment_service.dart';
import '../../../services/family_service.dart';
import '../../../services/hive_encryption_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/storage_service.dart';
import '../../../theme/app_brand.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/form_padding.dart';
import '../../../utils/format_helpers.dart';

class AppDiagnosticsScreen extends StatefulWidget {
  const AppDiagnosticsScreen({super.key});

  @override
  State<AppDiagnosticsScreen> createState() => _AppDiagnosticsScreenState();
}

class _DiagnosticsData {
  const _DiagnosticsData({
    required this.appVersion,
    required this.buildNumber,
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

class _AppDiagnosticsScreenState extends State<AppDiagnosticsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final List<Animation<double>> _sectionFades;

  _DiagnosticsData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _sectionFades = List.generate(
      4,
      (index) => CurvedAnimation(
        parent: _entryController,
        curve: Interval(
          index * 0.08,
          0.55 + index * 0.12,
          curve: Curves.easeOut,
        ),
      ),
    );
    _loadDiagnostics();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadDiagnostics() async {
    try {
      final data = await _collectDiagnostics();
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
        _loading = false;
      });
      _entryController.forward();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<_DiagnosticsData> _collectDiagnostics() async {
    final packageInfo = await PackageInfo.fromPlatform();
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

    return _DiagnosticsData(
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      packageName: packageInfo.packageName,
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

  String _yesNo(bool value) => value ? 'Yes' : 'No';

  String _enabledDisabled(bool value) => value ? 'Enabled' : 'Disabled';

  String _buildDiagnosticsReport(_DiagnosticsData data) {
    final buffer = StringBuffer()
      ..writeln('${AppBrand.name} Diagnostics')
      ..writeln()
      ..writeln('App Version: ${data.appVersion}')
      ..writeln('Build Number: ${data.buildNumber}')
      ..writeln('Package Name: ${data.packageName}')
      ..writeln('Build Mode: ${data.buildMode}')
      ..writeln()
      ..writeln('Platform: ${data.platform}')
      ..writeln('OS Version: ${data.osVersion}')
      ..writeln('Device Manufacturer: ${data.manufacturer}')
      ..writeln('Device Model: ${data.deviceModel}')
      ..writeln()
      ..writeln('Dark Mode: ${_enabledDisabled(data.darkModeEnabled)}')
      ..writeln('App Lock: ${_enabledDisabled(data.appLockEnabled)}')
      ..writeln(
        'Notifications: ${_enabledDisabled(data.notificationsEnabled)}',
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

  String? _getDiagnosticsReportText() {
    final data = _data;
    if (data == null) {
      return null;
    }
    return _buildDiagnosticsReport(data);
  }

  Future<void> _copyDiagnostics() async {
    final report = _getDiagnosticsReportText();
    if (report == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: report));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostics copied to clipboard.'),
      ),
    );
  }

  Future<void> _shareDiagnostics() async {
    final report = _getDiagnosticsReportText();
    if (report == null) {
      return;
    }

    await SharePlus.instance.share(ShareParams(text: report));
  }

  Widget _diagnosticTile({
    required String title,
    String? subtitle,
    String? value,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: value != null
          ? Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
    );
  }

  Widget _sectionCard({
    required Animation<double> fade,
    required String title,
    required List<Widget> children,
  }) {
    return FadeTransition(
      opacity: fade,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.cardPadding,
                AppSpacing.cardPadding,
                AppSpacing.cardPadding,
                AppSpacing.fieldLabelGap,
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Diagnostics'),
        actions: [
          if (!_loading && _error == null) ...[
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share',
              onPressed: _shareDiagnostics,
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copy',
              onPressed: _copyDiagnostics,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: listScrollPadding(context),
                      child: Text(
                        'Could not load diagnostics.\n$_error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final data = _data!;

    return ListView(
      padding: listScrollPadding(context),
      children: [
        _sectionCard(
          fade: _sectionFades[0],
          title: 'App Information',
          children: [
            _diagnosticTile(
              title: 'App Version',
              value: data.appVersion,
            ),
            _divider(),
            _diagnosticTile(
              title: 'Build Number',
              value: data.buildNumber,
            ),
            _divider(),
            _diagnosticTile(
              title: 'Package Name',
              value: data.packageName,
            ),
            _divider(),
            _diagnosticTile(
              title: 'Build Mode',
              value: data.buildMode,
            ),
          ],
        ),
        AppSpacing.gapSection,
        _sectionCard(
          fade: _sectionFades[1],
          title: 'Device Information',
          children: [
            _diagnosticTile(
              title: 'Platform',
              value: data.platform,
            ),
            _divider(),
            _diagnosticTile(
              title: 'OS Version',
              value: data.osVersion,
            ),
            _divider(),
            _diagnosticTile(
              title: 'Device Manufacturer',
              value: data.manufacturer,
            ),
            _divider(),
            _diagnosticTile(
              title: 'Device Model',
              value: data.deviceModel,
            ),
          ],
        ),
        AppSpacing.gapSection,
        _sectionCard(
          fade: _sectionFades[2],
          title: 'Application Information',
          children: [
            _diagnosticTile(
              title: 'Dark Mode Enabled',
              value: _yesNo(data.darkModeEnabled),
            ),
            _divider(),
            _diagnosticTile(
              title: 'App Lock Enabled',
              value: _yesNo(data.appLockEnabled),
            ),
            _divider(),
            _diagnosticTile(
              title: 'Notifications Enabled',
              value: _yesNo(data.notificationsEnabled),
            ),
            _divider(),
            _diagnosticTile(
              title: 'Last Backup Date',
              value: data.lastBackupDate,
            ),
            _divider(),
            _diagnosticTile(
              title: 'Total Renewals',
              value: '${data.totalRenewals}',
            ),
            _divider(),
            _diagnosticTile(
              title: 'Total Family Members',
              value: '${data.totalFamilyMembers}',
            ),
            _divider(),
            _diagnosticTile(
              title: 'Total Attachments',
              value: '${data.totalAttachments}',
            ),
          ],
        ),
        AppSpacing.gapSection,
        _sectionCard(
          fade: _sectionFades[3],
          title: 'Storage Information',
          children: [
            _diagnosticTile(
              title: 'Database Size',
              value: formatFileSize(data.databaseSizeBytes),
            ),
            _divider(),
            _diagnosticTile(
              title: 'Attachments Size',
              value: formatFileSize(data.attachmentsSizeBytes),
            ),
            _divider(),
            _diagnosticTile(
              title: 'Total App Storage Used',
              value: formatFileSize(data.totalStorageBytes),
            ),
          ],
        ),
      ],
    );
  }
}
