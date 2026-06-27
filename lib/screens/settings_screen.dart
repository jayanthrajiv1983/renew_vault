import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';



import '../providers/theme_provider.dart';

import '../services/backup_service.dart';

import '../services/notification_service.dart';

import '../services/settings_service.dart';

import '../theme/app_brand.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import '../widgets/renew_vault_logo.dart';
import '../widgets/reminder_interval_picker.dart';
import '../widgets/section_header.dart';

import 'family_members_screen.dart';



class SettingsScreen extends StatefulWidget {

  const SettingsScreen({super.key});



  static const appName = AppBrand.displayName;

  static const appVersion = AppBrand.version;

  static const appTagline = AppBrand.tagline;



  static const privacyPolicyUrl = '';

  static const termsUrl = '';

  static const supportEmail = 'support@renewvault.app';

  static const rateAppUrl = '';



  @override

  State<SettingsScreen> createState() => _SettingsScreenState();

}



class _SettingsScreenState extends State<SettingsScreen> {

  final _settings = SettingsService.instance;



  bool _isBackingUp = false;

  bool _isRestoring = false;

  bool _isExporting = false;

  bool _isImporting = false;



  late Set<int> _defaultReminderDays;

  late bool _enableNotifications;

  late bool _showExpiredBanner;

  late bool _autoSortByNearestExpiry;

  late bool _enableAppLock;

  late bool _hideAppContentsInRecents;



  bool get _isBusy =>

      _isBackingUp || _isRestoring || _isExporting || _isImporting;



  @override

  void initState() {

    super.initState();

    _loadSettings();

  }



  void _loadSettings() {

    _defaultReminderDays = _settings.getDefaultReminderDays().toSet();

    _enableNotifications = _settings.getEnableNotifications();

    _showExpiredBanner = _settings.getShowExpiredBanner();

    _autoSortByNearestExpiry = _settings.getAutoSortByNearestExpiry();

    _enableAppLock = _settings.getAppLockEnabled();

    _hideAppContentsInRecents = _settings.getHideAppContentsInRecents();

  }



  Future<void> _backupData() async {

    setState(() => _isBackingUp = true);



    try {

      final file = await BackupService.instance.exportToFile();



      if (!mounted) {

        return;

      }



      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Backup saved to ${file.path}')),

      );

    } on Exception catch (error) {

      if (!mounted) {

        return;

      }

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Backup failed: $error')),

      );

    } finally {

      if (mounted) {

        setState(() => _isBackingUp = false);

      }

    }

  }



  Future<void> _exportData() async {

    setState(() => _isExporting = true);



    try {

      final file = await BackupService.instance.exportToFile();

      await BackupService.instance.shareBackupFile(file);



      if (!mounted) {

        return;

      }



      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Backup exported successfully')),

      );

    } on Exception catch (error) {

      if (!mounted) {

        return;

      }

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Export failed: $error')),

      );

    } finally {

      if (mounted) {

        setState(() => _isExporting = false);

      }

    }

  }



  Future<void> _restoreOrImportData({required String actionLabel}) async {

    final isRestore = actionLabel == 'Restore';

    setState(() {

      if (isRestore) {

        _isRestoring = true;

      } else {

        _isImporting = true;

      }

    });



    try {

      final data = await BackupService.instance.pickAndReadBackup();

      BackupService.instance.validateBackup(data);



      if (!mounted) {

        return;

      }



      final confirmed = await showDialog<bool>(

        context: context,

        builder: (context) => AlertDialog(

          insetPadding: dialogInsetPadding(context),

          title: Text('$actionLabel backup?'),

          content: Text(

            'This will replace all renewals, family members, and settings '

            'with the data from the selected backup. This cannot be undone.',

          ),

          actions: [

            TextButton(

              onPressed: () => Navigator.of(context).pop(false),

              child: const Text('Cancel'),

            ),

            FilledButton(

              onPressed: () => Navigator.of(context).pop(true),

              child: Text(actionLabel),

            ),

          ],

        ),

      );



      if (confirmed != true || !mounted) {

        return;

      }



      await BackupService.instance.applyBackup(data);

      _loadSettings();



      if (!mounted) {

        return;

      }



      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Backup ${actionLabel.toLowerCase()}d successfully')),

      );

      Navigator.of(context).pop(true);

    } on BackupCancelledException {

      return;

    } on BackupValidationException catch (error) {

      if (!mounted) {

        return;

      }

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text(error.message)),

      );

    } on Exception catch (error) {

      if (!mounted) {

        return;

      }

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('$actionLabel failed: $error')),

      );

    } finally {

      if (mounted) {

        setState(() {

          _isRestoring = false;

          _isImporting = false;

        });

      }

    }

  }



  Future<void> _setDefaultReminderDays(List<int> days) async {

    await _settings.setDefaultReminderDays(days);

    setState(() => _defaultReminderDays = days.toSet());

  }



  Future<void> _setEnableNotifications(bool value) async {

    await _settings.setEnableNotifications(value);

    await NotificationService.instance.rescheduleAllReminders();

    setState(() => _enableNotifications = value);

  }



  Future<void> _setShowExpiredBanner(bool value) async {

    await _settings.setShowExpiredBanner(value);

    setState(() => _showExpiredBanner = value);

  }



  Future<void> _setAutoSortByNearestExpiry(bool value) async {

    await _settings.setAutoSortByNearestExpiry(value);

    setState(() => _autoSortByNearestExpiry = value);

  }



  Future<void> _setEnableAppLock(bool value) async {

    await _settings.setAppLockEnabled(value);

    setState(() => _enableAppLock = value);

  }



  Future<void> _setHideAppContentsInRecents(bool value) async {

    await _settings.setHideAppContentsInRecents(value);

    setState(() => _hideAppContentsInRecents = value);

  }



  Future<void> _openUrl(String url, {required String fallbackMessage}) async {

    if (url.isEmpty) {

      if (!mounted) {

        return;

      }

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text(fallbackMessage)),

      );

      return;

    }



    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {

      if (!mounted) {

        return;

      }

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Could not open $url')),

      );

    }

  }



  Future<void> _openFamilyMembersScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FamilyMembersScreen(),
      ),
    );
  }

  Future<void> _contactSupport() async {

    final uri = Uri(

      scheme: 'mailto',

      path: SettingsScreen.supportEmail,

      queryParameters: {

        'subject': '${SettingsScreen.appName} Support',

      },

    );



    if (!await launchUrl(uri)) {

      if (!mounted) {

        return;

      }

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Email us at ${SettingsScreen.supportEmail}'),

        ),

      );

    }

  }



  Widget _sectionHeader(String title) {
    return SectionHeader(
      title: title,
      padding: const EdgeInsets.only(bottom: AppSpacing.fieldLabelGap),
    );
  }



  Widget? _busyTrailing(bool busy) {

    if (!busy) {

      return null;

    }

    return const SizedBox(

      width: 24,

      height: 24,

      child: CircularProgressIndicator(strokeWidth: 2),

    );

  }



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);



    return Scaffold(

      resizeToAvoidBottomInset: true,

      appBar: AppBar(

        title: const Text('Settings'),

      ),

      body: SafeArea(

        child: ListView(

          padding: listScrollPadding(context),

          children: [

          _sectionHeader('Appearance'),

          ListenableBuilder(
            listenable: ThemeProvider.instance,
            builder: (context, _) {
              final themeMode = ThemeProvider.instance.appThemeMode;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.cardPadding,
                    AppSpacing.cardPadding,
                    AppSpacing.cardPadding,
                    AppSpacing.fieldLabelGap,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Mode',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.cardSpacing),
                      SegmentedButton<AppThemeMode>(
                        segments: AppThemeMode.values
                            .map(
                              (mode) => ButtonSegment(
                                value: mode,
                                label: Text(mode.label),
                              ),
                            )
                            .toList(),
                        selected: {themeMode},
                        onSelectionChanged: (selection) {
                          ThemeProvider.instance.setThemeMode(selection.first);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          AppSpacing.gapSection,

          _sectionHeader('App Preferences'),

          Card(

            child: Column(

              children: [

                SwitchListTile(

                  secondary: Icon(

                    Icons.warning_amber_outlined,

                    color: theme.colorScheme.primary,

                  ),

                  title: const Text('Show Expired Banner'),

                  subtitle: const Text('Display overdue alert on home screen'),

                  value: _showExpiredBanner,

                  onChanged: _setShowExpiredBanner,

                ),

                const Divider(height: 1),

                SwitchListTile(

                  secondary: Icon(

                    Icons.sort,

                    color: theme.colorScheme.primary,

                  ),

                  title: const Text('Auto Sort by Nearest Expiry'),

                  subtitle: const Text(

                    'Sort renewals by closest expiry date by default',

                  ),

                  value: _autoSortByNearestExpiry,

                  onChanged: _setAutoSortByNearestExpiry,

                ),

              ],

            ),

          ),

          AppSpacing.gapSection,

          _sectionHeader('Family'),

          Card(

            child: ListTile(

              leading: CircleAvatar(

                backgroundColor: theme.colorScheme.primaryContainer,

                child: Icon(

                  Icons.group_outlined,

                  color: theme.colorScheme.onPrimaryContainer,

                ),

              ),

              title: const Text('Manage Family Members'),

              subtitle: const Text('Add, edit, or remove family members'),

              trailing: const Icon(Icons.chevron_right),

              onTap: _openFamilyMembersScreen,

            ),

          ),

          AppSpacing.gapSection,

          _sectionHeader('Notifications'),

          Card(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                SwitchListTile(

                  secondary: Icon(

                    Icons.notifications_active_outlined,

                    color: theme.colorScheme.primary,

                  ),

                  title: const Text('Enable Notifications'),

                  subtitle: const Text('Schedule renewal reminder alerts'),

                  value: _enableNotifications,

                  onChanged: _setEnableNotifications,

                ),

                const Divider(height: 1),

                ReminderIntervalPicker(

                  title: 'Default Reminder Intervals',

                  subtitle: 'Applied when adding new renewals',

                  selectedDays: _defaultReminderDays,

                  contentPadding: const EdgeInsets.fromLTRB(
                    AppSpacing.cardPadding,
                    AppSpacing.cardPadding,
                    AppSpacing.cardPadding,
                    AppSpacing.cardPadding,
                  ),

                  onChanged: _setDefaultReminderDays,

                ),

              ],

            ),

          ),

          AppSpacing.gapSection,

          _sectionHeader('Security'),

          Card(

            child: Column(

              children: [

                SwitchListTile(

                  secondary: Icon(

                    Icons.lock_outline,

                    color: theme.colorScheme.primary,

                  ),

                  title: const Text('Enable App Lock'),

                  subtitle: const Text(

                    'Require fingerprint, face unlock, or device PIN to open the app',

                  ),

                  value: _enableAppLock,

                  onChanged: _setEnableAppLock,

                ),

                const Divider(height: 1),

                SwitchListTile(

                  secondary: Icon(

                    Icons.visibility_off_outlined,

                    color: theme.colorScheme.primary,

                  ),

                  title: const Text('Hide app contents in Recents'),

                  subtitle: const Text(

                    'Blur the app when backgrounded and block screenshots and recent-apps previews',

                  ),

                  value: _hideAppContentsInRecents,

                  onChanged: _setHideAppContentsInRecents,

                ),

              ],

            ),

          ),

          AppSpacing.gapSection,

          _sectionHeader('Data Management'),

          Card(

            child: Column(

              children: [

                ListTile(

                  leading: CircleAvatar(

                    backgroundColor: theme.colorScheme.primaryContainer,

                    child: Icon(

                      Icons.save,

                      color: theme.colorScheme.onPrimaryContainer,

                    ),

                  ),

                  title: const Text('Backup Data'),

                  subtitle: const Text('Save a JSON backup to local storage'),

                  trailing: _busyTrailing(_isBackingUp) ??

                      const Icon(Icons.chevron_right),

                  enabled: !_isBusy,

                  onTap: _isBusy ? null : _backupData,

                ),

                const Divider(height: 1),

                ListTile(

                  leading: CircleAvatar(

                    backgroundColor: theme.colorScheme.errorContainer,

                    child: Icon(

                      Icons.restore,

                      color: theme.colorScheme.onErrorContainer,

                    ),

                  ),

                  title: const Text('Restore Data'),

                  subtitle: const Text('Replace all data from a backup file'),

                  trailing: _busyTrailing(_isRestoring) ??

                      const Icon(Icons.chevron_right),

                  enabled: !_isBusy,

                  onTap: _isBusy

                      ? null

                      : () => _restoreOrImportData(actionLabel: 'Restore'),

                ),

                const Divider(height: 1),

                ListTile(

                  leading: CircleAvatar(

                    backgroundColor: theme.colorScheme.secondaryContainer,

                    child: Icon(

                      Icons.upload_file,

                      color: theme.colorScheme.onSecondaryContainer,

                    ),

                  ),

                  title: const Text('Export Data'),

                  subtitle: const Text('Share a JSON backup file'),

                  trailing: _busyTrailing(_isExporting) ??

                      const Icon(Icons.chevron_right),

                  enabled: !_isBusy,

                  onTap: _isBusy ? null : _exportData,

                ),

                const Divider(height: 1),

                ListTile(

                  leading: CircleAvatar(

                    backgroundColor: theme.colorScheme.tertiaryContainer,

                    child: Icon(

                      Icons.download,

                      color: theme.colorScheme.onTertiaryContainer,

                    ),

                  ),

                  title: const Text('Import Data'),

                  subtitle: const Text('Load data from a JSON backup file'),

                  trailing: _busyTrailing(_isImporting) ??

                      const Icon(Icons.chevron_right),

                  enabled: !_isBusy,

                  onTap: _isBusy

                      ? null

                      : () => _restoreOrImportData(actionLabel: 'Import'),

                ),

              ],

            ),

          ),

          AppSpacing.gapSection,

          _sectionHeader('About'),

          Card(

            child: Column(

              children: [

                Padding(

                  padding: const EdgeInsets.fromLTRB(

                    AppSpacing.cardPadding,

                    AppSpacing.sectionSpacing,

                    AppSpacing.cardPadding,

                    AppSpacing.fieldLabelGap,

                  ),

                  child: RenewVaultLogo(
                    size: 72,
                    showTagline: true,
                  ),

                ),

                ListTile(

                  leading: Icon(

                    Icons.info_outline,

                    color: theme.colorScheme.primary,

                  ),

                  title: Text(SettingsScreen.appName),

                  subtitle: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Version ${SettingsScreen.appVersion}'),
                      if (AppBrand.isBeta) ...[
                        const SizedBox(width: AppSpacing.fieldLabelGap),
                        Chip(
                          label: const Text('Beta'),
                          labelStyle: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide.none,
                        ),
                      ],
                    ],
                  ),

                ),

                const Divider(height: 1),

                ListTile(

                  leading: const Icon(Icons.privacy_tip_outlined),

                  title: const Text('Privacy Policy'),

                  trailing: const Icon(Icons.open_in_new, size: 18),

                  onTap: () => _openUrl(

                    SettingsScreen.privacyPolicyUrl,

                    fallbackMessage: 'Privacy policy link coming soon',

                  ),

                ),

                const Divider(height: 1),

                ListTile(

                  leading: const Icon(Icons.description_outlined),

                  title: const Text('Terms of Service'),

                  trailing: const Icon(Icons.open_in_new, size: 18),

                  onTap: () => _openUrl(

                    SettingsScreen.termsUrl,

                    fallbackMessage: 'Terms of service link coming soon',

                  ),

                ),

                const Divider(height: 1),

                ListTile(

                  leading: const Icon(Icons.support_agent_outlined),

                  title: const Text('Contact Support'),

                  trailing: const Icon(Icons.open_in_new, size: 18),

                  onTap: _contactSupport,

                ),

                const Divider(height: 1),

                ListTile(

                  leading: const Icon(Icons.star_outline),

                  title: const Text('Rate App'),

                  trailing: const Icon(Icons.open_in_new, size: 18),

                  onTap: () => _openUrl(

                    SettingsScreen.rateAppUrl,

                    fallbackMessage: 'App store rating coming soon',

                  ),

                ),

              ],

            ),

          ),

        ],

        ),

      ),

    );

  }

}


