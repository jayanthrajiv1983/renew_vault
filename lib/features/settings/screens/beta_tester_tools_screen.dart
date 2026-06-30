import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/crashlytics_service.dart';
import '../../../core/services/log_export_service.dart';
import '../../../core/services/logging_service.dart';
import '../../../services/app_lock_service.dart';
import '../../../services/backup_service.dart';
import '../../../services/beta_health_service.dart';
import '../../../services/diagnostics_report_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/ocr_service.dart';
import '../../../theme/app_brand.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/form_padding.dart';
import '../../../widgets/ocr/ocr_scan_helpers.dart';

class BetaTesterToolsScreen extends StatefulWidget {
  const BetaTesterToolsScreen({super.key});

  static const tabletBreakpoint = 600.0;

  @override
  State<BetaTesterToolsScreen> createState() => _BetaTesterToolsScreenState();
}

class _BetaTesterToolsScreenState extends State<BetaTesterToolsScreen> {
  static final ImagePicker _imagePicker = ImagePicker();

  bool _runningBackup = false;

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showBetaResultDialog(
    BuildContext context, {
    required bool success,
    required String message,
    String? details,
  }) async {
    if (!mounted) {
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: dialogInsetPadding(dialogContext),
        icon: Icon(
          success ? Icons.check_circle_rounded : Icons.error_rounded,
          color: success ? colorScheme.primary : colorScheme.error,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null) ...[
              const SizedBox(height: AppSpacing.fieldLabelGap),
              Text(
                details,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _recordHealthResult(
    BetaTestCategory category,
    bool success,
  ) async {
    await BetaHealthService.instance.setResult(
      category,
      success ? BetaTestResult.pass : BetaTestResult.fail,
    );
  }

  Future<void> _runTestNotifications() async {
    try {
      await NotificationService.instance.scheduleTestNotification();

      LoggingService.instance.logInfo(
        'BETA_TOOLS',
        'Notification test passed',
      );

      await _recordHealthResult(BetaTestCategory.notifications, true);
      _showSnackBar('Test notification scheduled for 10 seconds from now.');
    } catch (error) {
      LoggingService.instance.logError(
        'BETA_TOOLS',
        'Notification test failed',
      );
      await _recordHealthResult(BetaTestCategory.notifications, false);
      _showSnackBar('Notification test failed.');
    }
  }

  Future<void> _runTestBiometrics() async {
    try {
      final authenticated = await AppLockService.instance.authenticate();

      if (authenticated) {
        LoggingService.instance.logInfo(
          'BETA_TOOLS',
          'Biometric test passed',
        );
        await _recordHealthResult(BetaTestCategory.biometrics, true);
        if (mounted) {
          await _showBetaResultDialog(
            context,
            success: true,
            message: 'Biometric authentication successful.',
          );
        }
      } else {
        LoggingService.instance.logError(
          'BETA_TOOLS',
          'Biometric test failed',
        );
        await _recordHealthResult(BetaTestCategory.biometrics, false);
        if (mounted) {
          await _showBetaResultDialog(
            context,
            success: false,
            message: 'Biometric authentication failed.',
          );
        }
      }
    } catch (error) {
      LoggingService.instance.logError(
        'BETA_TOOLS',
        'Biometric test failed',
      );
      await _recordHealthResult(BetaTestCategory.biometrics, false);
      if (mounted) {
        await _showBetaResultDialog(
          context,
          success: false,
          message: 'Biometric authentication failed.',
        );
      }
    }
  }

  Future<void> _runTestOcr() async {
    try {
      final source = await showOcrSourcePicker(context);
      if (source == null || !mounted) {
        return;
      }

      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null || !mounted) {
        return;
      }

      var overlayShown = false;
      final stopwatch = Stopwatch()..start();

      try {
        if (mounted) {
          overlayShown = true;
          showOcrScanningOverlay(context);
        }

        final result = await OcrService.fastScanAndParse(image.path);
        stopwatch.stop();

        if (overlayShown && mounted) {
          dismissOcrScanningOverlay(context);
          overlayShown = false;
        }

        final fieldCount = result.fields
            .where((field) => field.extractedValue.trim().isNotEmpty)
            .length;
        final processingMs = stopwatch.elapsedMilliseconds;

        LoggingService.instance.logInfo(
          'BETA_TOOLS',
          'OCR test passed (${processingMs}ms, $fieldCount fields)',
        );

        await _recordHealthResult(BetaTestCategory.ocr, true);
        if (mounted) {
          await _showBetaResultDialog(
            context,
            success: true,
            message: 'OCR completed successfully.',
            details:
                'Processing time: ${processingMs}ms\nExtracted fields: $fieldCount',
          );
        }
      } finally {
        if (overlayShown && mounted) {
          dismissOcrScanningOverlay(context);
        }
      }
    } catch (error) {
      LoggingService.instance.logError('BETA_TOOLS', 'OCR test failed');
      await _recordHealthResult(BetaTestCategory.ocr, false);
      if (mounted) {
        await _showBetaResultDialog(
          context,
          success: false,
          message: 'OCR failed.',
        );
      }
    }
  }

  Future<void> _runTestBackup() async {
    if (_runningBackup) {
      return;
    }

    setState(() => _runningBackup = true);
    File? tempFile;

    try {
      tempFile = await BackupService.instance.exportEncryptedBackup();
      final bytes = await tempFile.readAsBytes();
      await BackupService.instance.previewRvbackupBytes(bytes);

      LoggingService.instance.logInfo('BETA_TOOLS', 'Backup test passed');

      await _recordHealthResult(BetaTestCategory.backup, true);
      if (mounted) {
        await _showBetaResultDialog(
          context,
          success: true,
          message: 'Backup system operational.',
        );
      }
    } catch (error) {
      LoggingService.instance.logError('BETA_TOOLS', 'Backup test failed');
      await _recordHealthResult(BetaTestCategory.backup, false);
      if (mounted) {
        await _showBetaResultDialog(
          context,
          success: false,
          message: 'Backup validation failed.',
        );
      }
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
      if (mounted) {
        setState(() => _runningBackup = false);
      }
    }
  }

  Future<void> _exportDiagnostics() async {
    try {
      final report = await DiagnosticsReportService.instance.collectReportText();

      if (!mounted) {
        return;
      }

      final action = await showDialog<_DiagnosticsExportAction>(
        context: context,
        builder: (context) => AlertDialog(
          insetPadding: dialogInsetPadding(context),
          title: const Text('Export Diagnostics'),
          content: const Text(
            'Share the diagnostics report or copy it to the clipboard.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_DiagnosticsExportAction.copy),
              child: const Text('Copy'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_DiagnosticsExportAction.share),
              child: const Text('Share'),
            ),
          ],
        ),
      );

      if (action == null || !mounted) {
        return;
      }

      if (action == _DiagnosticsExportAction.copy) {
        await Clipboard.setData(ClipboardData(text: report));
        _showSnackBar('Diagnostics copied to clipboard.');
      } else {
        await SharePlus.instance.share(ShareParams(text: report));
      }

      LoggingService.instance.logInfo(
        'BETA_TOOLS',
        'Diagnostics export executed',
      );
    } catch (error) {
      LoggingService.instance.logError(
        'BETA_TOOLS',
        'Diagnostics export failed',
      );
      _showSnackBar('Diagnostics export failed.');
    }
  }

  String _crashReportingCollectionHint() {
    final crashlytics = CrashlyticsService.instance;
    if (!crashlytics.hasUserConsent) {
      return 'Enable crash reporting in Settings → Privacy & Security for reports to upload.';
    }
    if (!kReleaseMode) {
      return 'Debug build: Crashlytics collection is disabled; reports will not upload.';
    }
    return 'Test sent. Check the Firebase Crashlytics console for the report.';
  }

  Future<void> _showCrashReportingTestPicker() async {
    final action = await showDialog<_CrashReportingTestAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: dialogInsetPadding(dialogContext),
        title: const Text('Test Crash Reporting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose a test type. Non-fatal sends a report without closing the app.',
            ),
            const SizedBox(height: AppSpacing.fieldSpacing),
            ListTile(
              leading: const Icon(Icons.error_outline_rounded),
              title: const Text('Send Test Non-Fatal Error'),
              subtitle: const Text('Records a non-fatal error to Crashlytics.'),
              onTap: () => Navigator.of(dialogContext)
                  .pop(_CrashReportingTestAction.nonFatal),
            ),
            ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(dialogContext).colorScheme.error,
              ),
              title: const Text('Trigger Test Crash'),
              subtitle: const Text('Force-closes the app after confirmation.'),
              onTap: () => Navigator.of(dialogContext)
                  .pop(_CrashReportingTestAction.crash),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (action == null || !mounted) {
      return;
    }

    switch (action) {
      case _CrashReportingTestAction.nonFatal:
        await _runTestCrashReportingNonFatal();
      case _CrashReportingTestAction.crash:
        await _runTestCrashReportingCrash();
    }
  }

  Future<void> _runTestCrashReportingNonFatal() async {
    try {
      await CrashlyticsService.instance.testNonFatal();

      LoggingService.instance.logInfo(
        'CRASHLYTICS',
        'Test non-fatal error sent',
      );
      LoggingService.instance.logInfo(
        'BETA_TOOLS',
        'Crash reporting non-fatal test executed',
      );

      _showSnackBar(_crashReportingCollectionHint());
    } catch (error) {
      LoggingService.instance.logError(
        'BETA_TOOLS',
        'Crash reporting non-fatal test failed',
      );
      _showSnackBar('Non-fatal crash test failed.');
    }
  }

  Future<void> _runTestCrashReportingCrash() async {
    if (!mounted) {
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: dialogInsetPadding(dialogContext),
        icon: Icon(
          Icons.warning_rounded,
          color: colorScheme.error,
        ),
        title: const Text('Trigger Test Crash?'),
        content: const Text('This will force-close the app. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Crash App'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    LoggingService.instance.logInfo('CRASHLYTICS', 'Test crash executed');
    LoggingService.instance.logInfo(
      'BETA_TOOLS',
      'Crash reporting crash test executed',
    );

    CrashlyticsService.instance.testCrash();
  }

  Future<void> _exportDebugLogs() async {
    try {
      final logs = LoggingService.instance.getLogs();
      if (logs.isEmpty) {
        _showSnackBar('No logs to export.');
        return;
      }

      final export = await LogExportService.instance.generateExportFile(
        logs: logs,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(export.file.path)],
          subject: 'Renew Vault Debug Logs',
        ),
      );

      LoggingService.instance.logInfo(
        'BETA_TOOLS',
        'Debug logs export executed',
      );

      _showSnackBar('Debug logs exported successfully.');
    } catch (error) {
      LoggingService.instance.logError(
        'BETA_TOOLS',
        'Debug logs export failed',
      );
      _showSnackBar('Debug logs export failed.');
    }
  }

  List<_BetaToolDefinition> get _tools => [
        _BetaToolDefinition(
          icon: Icons.notifications_active_rounded,
          title: 'Test Notifications',
          subtitle: 'Send a test notification after 10 seconds.',
          onRun: _runTestNotifications,
        ),
        _BetaToolDefinition(
          icon: Icons.fingerprint_rounded,
          title: 'Test Biometrics',
          subtitle:
              'Verify fingerprint, face unlock, or device PIN authentication.',
          onRun: _runTestBiometrics,
        ),
        _BetaToolDefinition(
          icon: Icons.document_scanner_rounded,
          title: 'Test OCR',
          subtitle: 'Pick an image and run a document OCR scan test.',
          onRun: _runTestOcr,
        ),
        _BetaToolDefinition(
          icon: Icons.backup_rounded,
          title: 'Test Backup',
          subtitle: 'Create a temporary backup and validate integrity.',
          onRun: _runningBackup ? null : _runTestBackup,
          running: _runningBackup,
        ),
        _BetaToolDefinition(
          icon: Icons.bug_report_rounded,
          title: 'Test Crash Reporting',
          subtitle:
              'Verify Crashlytics non-fatal reports and crash capture.',
          onRun: _showCrashReportingTestPicker,
        ),
        _BetaToolDefinition(
          icon: Icons.health_and_safety_rounded,
          title: 'Export Diagnostics',
          subtitle: 'Export an app and device diagnostics report.',
          onRun: _exportDiagnostics,
        ),
        _BetaToolDefinition(
          icon: Icons.receipt_long_rounded,
          title: 'Export Debug Logs',
          subtitle: 'Export application logs as a TXT file.',
          onRun: _exportDebugLogs,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final tools = _tools;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beta Tester Tools'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet =
                constraints.maxWidth >= BetaTesterToolsScreen.tabletBreakpoint;
            final padding = listScrollPadding(context);

            if (isTablet) {
              const crossAxisCount = 2;
              final horizontalPadding = padding.left + padding.right;
              final spacing = AppSpacing.cardSpacing;
              final availableWidth = constraints.maxWidth -
                  horizontalPadding -
                  spacing * (crossAxisCount - 1);
              final itemWidth = availableWidth / crossAxisCount;

              return SingleChildScrollView(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BetaHealthCheckCard(),
                    SizedBox(height: spacing),
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (var i = 0; i < tools.length; i++)
                          SizedBox(
                            width: itemWidth,
                            child: _StaggeredFadeIn(
                              index: i,
                              child: _BetaToolCard(
                                icon: tools[i].icon,
                                title: tools[i].title,
                                subtitle: tools[i].subtitle,
                                onRun: tools[i].onRun,
                                running: tools[i].running,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: padding,
              children: [
                const _BetaHealthCheckCard(),
                AppSpacing.gapCard,
                for (var index = 0; index < tools.length; index++) ...[
                  if (index > 0) AppSpacing.gapCard,
                  _StaggeredFadeIn(
                    index: index,
                    child: _BetaToolCard(
                      icon: tools[index].icon,
                      title: tools[index].title,
                      subtitle: tools[index].subtitle,
                      onRun: tools[index].onRun,
                      running: tools[index].running,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _DiagnosticsExportAction { copy, share }

enum _CrashReportingTestAction { nonFatal, crash }

class _BetaHealthCheckCard extends StatelessWidget {
  const _BetaHealthCheckCard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BetaHealthService.instance,
      builder: (context, _) {
        final results = BetaHealthService.instance.getAllResults();
        return _BetaHealthCheckCardContent(results: results);
      },
    );
  }
}

class _BetaHealthCheckCardContent extends StatelessWidget {
  const _BetaHealthCheckCardContent({required this.results});

  final Map<BetaTestCategory, BetaTestResult> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: AppSpacing.cardInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.monitor_heart_rounded,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.fieldLabelGap),
                Expanded(
                  child: Text(
                    'Beta Health Check',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.fieldSpacing),
            for (final category in BetaTestCategory.values) ...[
              _BetaHealthCheckRow(
                label: category.label,
                result: results[category] ?? BetaTestResult.notTested,
              ),
              if (category != BetaTestCategory.values.last)
                const SizedBox(height: AppSpacing.fieldLabelGap),
            ],
          ],
        ),
      ),
    );
  }
}

class _BetaHealthCheckRow extends StatelessWidget {
  const _BetaHealthCheckRow({
    required this.label,
    required this.result,
  });

  final String label;
  final BetaTestResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chipStyle = _chipStyle(result, colorScheme);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Chip(
          label: Text(
            chipStyle.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: chipStyle.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: chipStyle.background,
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ],
    );
  }

  _BetaHealthChipStyle _chipStyle(
    BetaTestResult result,
    ColorScheme colorScheme,
  ) {
    switch (result) {
      case BetaTestResult.pass:
        return _BetaHealthChipStyle(
          label: 'PASS',
          background: AppBrand.green.withValues(alpha: 0.18),
          foreground: AppBrand.green,
        );
      case BetaTestResult.fail:
        return _BetaHealthChipStyle(
          label: 'FAIL',
          background: colorScheme.errorContainer,
          foreground: colorScheme.onErrorContainer,
        );
      case BetaTestResult.notTested:
        return _BetaHealthChipStyle(
          label: 'Not Tested',
          background: colorScheme.surfaceContainerHighest,
          foreground: colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _BetaHealthChipStyle {
  const _BetaHealthChipStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

class _BetaToolDefinition {
  const _BetaToolDefinition({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRun,
    this.running = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function()? onRun;
  final bool running;
}

class _BetaToolCard extends StatelessWidget {
  const _BetaToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRun,
    this.running = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function()? onRun;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: AppSpacing.cardInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                icon,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.fieldLabelGap),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.fieldLabelGap),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.fieldSpacing),
            FilledButton.icon(
              onPressed: running || onRun == null
                  ? null
                  : () async {
                      await onRun!();
                    },
              icon: running
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(running ? 'Running…' : 'Run Test'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredFadeIn extends StatefulWidget {
  const _StaggeredFadeIn({
    required this.index,
    required this.child,
  });

  static const _delayPerItem = Duration(milliseconds: 50);
  static const _duration = Duration(milliseconds: 350);

  final int index;
  final Widget child;

  @override
  State<_StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<_StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _started = false;

  bool _shouldAnimate(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.disableAnimations) {
      return false;
    }
    return !SchedulerBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: _StaggeredFadeIn._duration);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _fade = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;

    if (!_shouldAnimate(context)) {
      _controller.value = 1;
      return;
    }

    final delay = _StaggeredFadeIn._delayPerItem * widget.index;
    Future<void>.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldAnimate(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
