import 'package:flutter/material.dart';

import '../core/services/logging_service.dart';
import '../core/services/crashlytics_service.dart';
import '../models/backup_reminder_interval.dart';

import 'package:url_launcher/url_launcher.dart';



import '../models/backup_preview.dart';
import '../providers/theme_provider.dart';

import '../services/app_info_service.dart';
import '../services/backup_service.dart';

import '../services/app_lock_service.dart';

import '../services/feedback_service.dart';

import '../services/notification_service.dart';

import '../services/settings_service.dart';

import '../shared/widgets/success_overlay.dart';
import '../theme/app_spacing.dart';
import '../utils/backup_flow.dart';
import '../utils/form_padding.dart';
import '../widgets/restore_progress_dialog.dart';
import '../widgets/renew_vault_logo.dart';
import '../widgets/reminder_interval_picker.dart';
import '../widgets/section_header.dart';

import '../features/settings/screens/app_diagnostics_screen.dart';
import '../features/settings/screens/beta_tester_tools_screen.dart';
import '../features/settings/screens/debug_logs_screen.dart';
import 'backup_history_screen.dart';
import 'family_members_screen.dart';
import 'notifications_screen.dart';
import 'upcoming_renewals_screen.dart';



class SettingsScreen extends StatefulWidget {

  const SettingsScreen({super.key});



  static const privacyPolicyUrl = '';

  static const termsUrl = '';

  static const supportEmail = 'jayanthrajiv@gmail.com';

  static const rateAppUrl = '';



  @override

  State<SettingsScreen> createState() => _SettingsScreenState();

}



class _SettingsScreenState extends State<SettingsScreen> {

  final _settings = SettingsService.instance;



  bool _isBackingUp = false;

  bool _isRestoring = false;

  bool _isImporting = false;



  late Set<int> _defaultReminderDays;

  late bool _enableNotifications;

  late bool _showExpiredBanner;

  late bool _autoSortByNearestExpiry;

  late bool _enableAppLock;

  late bool _hideAppContentsInRecents;

  late bool _crashReportingEnabled;

  late BackupReminderInterval _backupReminderInterval;



  bool get _isBusy => _isBackingUp || _isRestoring || _isImporting;



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

    _crashReportingEnabled = _settings.getCrashReportingEnabled();

    _backupReminderInterval = _settings.getBackupReminderInterval();

  }



  Future<void> _backupData() async {
    setState(() => _isBackingUp = true);

    try {
      await runEncryptedBackupFlow(context);
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }



  Future<void> _restoreOrImportData({
    required List<String> allowedExtensions,
    required String actionLabel,
    required bool isRestore,
  }) async {
    setState(() {
      if (isRestore) {
        _isRestoring = true;
      } else {
        _isImporting = true;
      }
    });

    try {
      final pickResult = await BackupService.instance.pickBackupFile(
        allowedExtensions: allowedExtensions,
      );

      if (pickResult == null || !mounted) {
        return;
      }

      final previewResult = await showRestorePreviewProgressDialog(
        context,
        (onProgress) => BackupService.instance.previewPickedBackup(
          pickResult,
          onProgress: onProgress,
        ),
      );

      if (!mounted) {
        return;
      }

      if (previewResult is BackupValidationException) {
        await showRestoreErrorDialog(
          context,
          message: previewResult.message,
        );
        return;
      }

      if (previewResult is Exception) {
        await showRestoreErrorDialog(
          context,
          message: previewResult.toString(),
        );
        return;
      }

      if (previewResult is! BackupPreview) {
        return;
      }

      final confirmed = await showRestoreSummaryDialog(context, previewResult);
      if (confirmed != true || !mounted) {
        return;
      }

      final restored = await showRestoreApplyProgressDialog(
        context,
        (onProgress) => BackupService.instance.restoreFromPreview(
          previewResult,
          onProgress: onProgress,
        ),
      );

      if (!restored || !mounted) {
        return;
      }

      _loadSettings();

      if (!mounted) {
        return;
      }

      if (isRestore) {
        await SuccessOverlay.show(
          context,
          message: 'Restore complete',
        );
        if (!mounted) {
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup ${actionLabel.toLowerCase()}d successfully'),
        ),
      );
      Navigator.of(context).pop(true);
    } on BackupValidationException catch (error, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureRestore,
        'Restore validation failed',
        exception: error,
        stackTrace: stack,
        operation: 'Restore Failed',
      );
      if (!mounted) {
        return;
      }
      await showRestoreErrorDialog(context, message: error.message);
    } on Exception catch (error, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureRestore,
        'Restore failed',
        exception: error,
        stackTrace: stack,
        operation: 'Restore Failed',
      );
      if (!mounted) {
        return;
      }
      await showRestoreErrorDialog(
        context,
        message: '$actionLabel failed: $error',
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



  Future<void> _testBiometricAuthentication() async {
    final authenticated = await AppLockService.instance.authenticate();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authenticated
              ? 'Authentication successful'
              : 'Authentication failed',
        ),
      ),
    );
  }



  Future<void> _setHideAppContentsInRecents(bool value) async {

    await _settings.setHideAppContentsInRecents(value);

    setState(() => _hideAppContentsInRecents = value);

  }



  Future<void> _setCrashReportingEnabled(bool value) async {
    await _settings.setCrashReportingEnabled(value);
    await CrashlyticsService.instance.updateConsent(value);
    LoggingService.instance.logInfo(
      'APP',
      'Crash reporting consent: ${value ? 'granted' : 'denied'}',
    );
    setState(() => _crashReportingEnabled = value);
  }



  Future<void> _setBackupReminderInterval(BackupReminderInterval interval) async {
    await _settings.setBackupReminderInterval(interval);
    setState(() => _backupReminderInterval = interval);
  }

  void _openBackupReminderSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: bottomSheetPadding(sheetContext),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Backup Reminder',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.fieldLabelGap),
                Text(
                  'Show a reminder on the home screen when a backup is overdue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.sectionSpacing),
                ...BackupReminderInterval.values.map(
                  (interval) => RadioListTile<BackupReminderInterval>(
                    title: Text(interval.label),
                    value: interval,
                    groupValue: _backupReminderInterval,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      _setBackupReminderInterval(value);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Future<void> _openBackupHistoryScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BackupHistoryScreen(),
      ),
    );
  }

  Future<void> _openNotificationsScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  Future<void> _openUpcomingRenewalsScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UpcomingRenewalsScreen(),
      ),
    );
  }

  Future<void> _openAppDiagnosticsScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AppDiagnosticsScreen(),
      ),
    );
  }

  Future<void> _openDebugLogsScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DebugLogsScreen(),
      ),
    );
  }

  Future<void> _openBetaTesterToolsScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BetaTesterToolsScreen(),
      ),
    );
  }

  Future<void> _launchFeedback(FeedbackType type) async {
    await FeedbackService.instance.launchFeedback(
      context: context,
      type: type,
    );
  }

  Widget _feedbackListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required FeedbackType type,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(
          icon,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _launchFeedback(type),
    );
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

                ListTile(

                  leading: Icon(

                    Icons.notifications_none,

                    color: theme.colorScheme.primary,

                  ),

                  title: const Text('Scheduled Reminders'),

                  subtitle: const Text('View upcoming reminder alerts'),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: _openNotificationsScreen,

                ),

                const Divider(height: 1),

                ListTile(

                  leading: Icon(

                    Icons.event_available,

                    color: theme.colorScheme.primary,

                  ),

                  title: const Text('Upcoming Renewals'),

                  subtitle: const Text('Renewals with reminders on the way'),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: _openUpcomingRenewalsScreen,

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

          _sectionHeader('Privacy & Security'),

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

                ListTile(

                  leading: Icon(

                    Icons.fingerprint,

                    color: theme.colorScheme.primary,

                  ),

                  title: const Text('Test Biometric Authentication'),

                  subtitle: const Text(

                    'Verify fingerprint, face unlock, or device PIN prompt',

                  ),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: _testBiometricAuthentication,

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

                const Divider(height: 1),

                SwitchListTile(

                  secondary: Icon(

                    Icons.bug_report_outlined,

                    color: theme.colorScheme.primary,

                  ),

                  title: const Text('Share Anonymous Crash Reports'),

                  subtitle: const Text(

                    'Send anonymous crash data to help improve app stability. No personal documents or sensitive information are shared.',

                  ),

                  value: _crashReportingEnabled,

                  onChanged: _setCrashReportingEnabled,

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

                    backgroundColor: theme.colorScheme.secondaryContainer,

                    child: Icon(

                      Icons.schedule_outlined,

                      color: theme.colorScheme.onSecondaryContainer,

                    ),

                  ),

                  title: const Text('Backup Reminder'),

                  subtitle: Text(_backupReminderInterval.label),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: _openBackupReminderSheet,

                ),

                const Divider(height: 1),

                ListTile(

                  leading: CircleAvatar(

                    backgroundColor: theme.colorScheme.surfaceContainerHighest,

                    child: Icon(

                      Icons.history,

                      color: theme.colorScheme.onSurfaceVariant,

                    ),

                  ),

                  title: const Text('Backup History'),

                  subtitle: const Text('View past backups and share again'),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: _openBackupHistoryScreen,

                ),

                const Divider(height: 1),

                ListTile(

                  leading: CircleAvatar(

                    backgroundColor: theme.colorScheme.primaryContainer,

                    child: Icon(

                      Icons.save,

                      color: theme.colorScheme.onPrimaryContainer,

                    ),

                  ),

                  title: const Text('Backup Data'),

                  subtitle: const Text(
                    'Create encrypted backup and save or share via Drive, iCloud, email, etc.',
                  ),

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

                  subtitle: const Text(
                    'Replace all data from an encrypted .rvbackup file',
                  ),

                  trailing: _busyTrailing(_isRestoring) ??

                      const Icon(Icons.chevron_right),

                  enabled: !_isBusy,

                  onTap: _isBusy
                      ? null
                      : () => _restoreOrImportData(
                            allowedExtensions: const ['rvbackup'],
                            actionLabel: 'Restore',
                            isRestore: true,
                          ),

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

                  subtitle: const Text(
                    'Load data from a .rvbackup or legacy JSON backup',
                  ),

                  trailing: _busyTrailing(_isImporting) ??

                      const Icon(Icons.chevron_right),

                  enabled: !_isBusy,

                  onTap: _isBusy
                      ? null
                      : () => _restoreOrImportData(
                            allowedExtensions: const ['rvbackup', 'json'],
                            actionLabel: 'Import',
                            isRestore: false,
                          ),

                ),

              ],

            ),

          ),

          AppSpacing.gapSection,

          _sectionHeader('Feedback & Support'),

          Card(
            child: Column(
              children: [
                _feedbackListTile(
                  icon: Icons.feedback_rounded,
                  title: 'Send Feedback',
                  subtitle: 'Share your experience with Renew Vault',
                  type: FeedbackType.feedback,
                  colorScheme: theme.colorScheme,
                ),
                const Divider(height: 1),
                _feedbackListTile(
                  icon: Icons.bug_report_rounded,
                  title: 'Report a Bug',
                  subtitle: 'Tell us about something that is not working',
                  type: FeedbackType.bugReport,
                  colorScheme: theme.colorScheme,
                ),
                const Divider(height: 1),
                _feedbackListTile(
                  icon: Icons.lightbulb_rounded,
                  title: 'Request a Feature',
                  subtitle: 'Suggest an improvement or new capability',
                  type: FeedbackType.featureRequest,
                  colorScheme: theme.colorScheme,
                ),
                const Divider(height: 1),
                _feedbackListTile(
                  icon: Icons.support_agent_rounded,
                  title: 'Contact Support',
                  subtitle: 'Get help from the Renew Vault team',
                  type: FeedbackType.support,
                  colorScheme: theme.colorScheme,
                ),
              ],
            ),
          ),

          AppSpacing.gapSection,

          _sectionHeader('Diagnostics'),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: const Text('App Diagnostics'),
                  subtitle: const Text(
                    'View app, device, and storage information',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openAppDiagnosticsScreen,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.article_outlined,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: const Text('Debug Logs'),
                  subtitle: const Text(
                    'View and export application event logs',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openDebugLogsScreen,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    child: Icon(
                      Icons.science_rounded,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                  title: const Text('Beta Tester Tools'),
                  subtitle: const Text(
                    'Run tests for notifications, OCR, backup, and more',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openBetaTesterToolsScreen,
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

                    AppSpacing.cardPadding,

                  ),

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      const RenewVaultLogo(

                        size: 72,

                        showTagline: true,

                      ),

                      const SizedBox(height: AppSpacing.sectionSpacing),

                      _AboutVersionInfo(theme: theme),

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



class _AboutVersionInfo extends StatelessWidget {

  const _AboutVersionInfo({required this.theme});



  final ThemeData theme;



  @override

  Widget build(BuildContext context) {

    final appInfo = AppInfoService.instance;

    final versionText = appInfo.formattedVersionStringSync;

    final releaseChannel = appInfo.releaseChannel;



    if (versionText == null) {
      return FutureBuilder<void>(
        future: appInfo.init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Text(
              'Loading version…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            );
          }
          if (snapshot.hasError) {
            return Text(
              'Version unavailable',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            );
          }
          final loadedText = appInfo.formattedVersionStringSync;
          if (loadedText == null) {
            return Text(
              'Version unavailable',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            );
          }
          return _AboutVersionBody(
            theme: theme,
            versionText: loadedText,
            releaseChannel: releaseChannel,
          );
        },
      );
    }

    return _AboutVersionBody(
      theme: theme,
      versionText: versionText,
      releaseChannel: releaseChannel,
    );
  }
}

class _AboutVersionBody extends StatelessWidget {
  const _AboutVersionBody({
    required this.theme,
    required this.versionText,
    required this.releaseChannel,
  });

  final ThemeData theme;
  final String versionText;
  final String releaseChannel;

  @override
  Widget build(BuildContext context) {
    return Column(

      mainAxisSize: MainAxisSize.min,

      children: [

        Text(

          versionText,

          style: theme.textTheme.bodyMedium?.copyWith(

            color: theme.colorScheme.onSurfaceVariant,

          ),

          textAlign: TextAlign.center,

        ),

        if (releaseChannel.isNotEmpty) ...[

          const SizedBox(height: AppSpacing.fieldLabelGap),

          Chip(

            label: Text(releaseChannel),

            labelStyle: theme.textTheme.labelSmall?.copyWith(

              color: theme.colorScheme.onPrimaryContainer,

              fontWeight: FontWeight.w600,

            ),

            backgroundColor: theme.colorScheme.primaryContainer,

            padding: EdgeInsets.zero,

            visualDensity: VisualDensity.compact,

            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

            side: BorderSide.none,

          ),

        ],

      ],

    );

  }

}


