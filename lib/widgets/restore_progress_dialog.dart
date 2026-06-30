import 'package:flutter/material.dart';

import '../models/backup_integrity_result.dart';
import '../models/backup_preview.dart';
import '../services/backup_service.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';

/// Material 3 progress dialog while verifying backup integrity before restore.
/// Returns a [BackupIntegrityResult] on completion.
Future<BackupIntegrityResult?> showBackupVerificationProgressDialog(
  BuildContext context,
  Future<BackupIntegrityResult> Function(RestoreProgressCallback onProgress)
      task,
) async {
  return showDialog<BackupIntegrityResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _BackupVerificationProgressDialog(task: task),
  );
}

/// Shows whether pre-restore integrity verification passed or failed.
Future<void> showBackupVerificationResultDialog(
  BuildContext context, {
  required bool success,
}) {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      insetPadding: dialogInsetPadding(context),
      icon: Icon(
        success ? Icons.verified_outlined : Icons.error_outline,
        color: success ? theme.colorScheme.primary : theme.colorScheme.error,
      ),
      title: Text(success ? 'Backup Verified' : 'Backup Corrupted'),
      content: Text(
        success
            ? 'Backup verified successfully'
            : 'Backup appears corrupted',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Material 3 progress dialog while reading and decrypting a backup for preview.
/// Returns a [BackupPreview] on success, or an [Exception] on failure.
Future<Object?> showRestorePreviewProgressDialog(
  BuildContext context,
  Future<BackupPreview> Function(RestoreProgressCallback onProgress) task,
) async {
  return showDialog<Object>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _RestorePreviewProgressDialog(task: task),
  );
}

/// Material 3 progress dialog while applying a confirmed backup restore.
Future<bool> showRestoreApplyProgressDialog(
  BuildContext context,
  Future<void> Function(RestoreProgressCallback onProgress) task,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _RestoreApplyProgressDialog(task: task),
  );
  return result ?? false;
}

/// Material 3 summary dialog shown before restoring a validated backup.
Future<bool> showRestoreSummaryDialog(
  BuildContext context,
  BackupPreview preview,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      insetPadding: dialogInsetPadding(context),
      title: const Text('Restore Backup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Backup contains:'),
          const SizedBox(height: AppSpacing.fieldLabelGap),
          Text('- ${preview.renewalCount} Renewals'),
          Text('- ${preview.familyMemberCount} Family Members'),
          Text('- ${preview.attachmentCount} Attachments'),
          const SizedBox(height: AppSpacing.cardSpacing),
          const Text('Restore this backup?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Restore'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Warns that restoring will replace all current on-device data.
Future<bool> showRestoreDataReplacementDialog(
  BuildContext context, {
  required String backupName,
}) async {
  final theme = Theme.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      insetPadding: dialogInsetPadding(context),
      icon: Icon(
        Icons.warning_amber_rounded,
        color: theme.colorScheme.error,
      ),
      title: const Text('Replace Current Data?'),
      content: Text(
        'Restoring "$backupName" will replace all renewal data on this device. '
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Material 3 error dialog for invalid or corrupted backup files.
Future<void> showRestoreErrorDialog(
  BuildContext context, {
  required String message,
}) {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      insetPadding: dialogInsetPadding(context),
      icon: Icon(
        Icons.error_outline,
        color: theme.colorScheme.error,
      ),
      title: const Text('Unable to Restore'),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class _BackupVerificationProgressDialog extends StatefulWidget {
  const _BackupVerificationProgressDialog({required this.task});

  final Future<BackupIntegrityResult> Function(
    RestoreProgressCallback onProgress,
  ) task;

  @override
  State<_BackupVerificationProgressDialog> createState() =>
      _BackupVerificationProgressDialogState();
}

class _BackupVerificationProgressDialogState
    extends State<_BackupVerificationProgressDialog> {
  RestoreProgressStep _step = RestoreProgressStep.verifyingBackup;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _runTask();
  }

  Future<void> _runTask() async {
    try {
      final result = await widget.task((step, progress) {
        if (!mounted) {
          return;
        }
        setState(() {
          _step = step;
          _progress = progress;
        });
      });

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    } on Exception {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        BackupIntegrityResult.failure(BackupIntegrityCheck.fileReadable),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      insetPadding: dialogInsetPadding(context),
      title: const Text('Verifying Backup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _step.label,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.cardSpacing),
          LinearProgressIndicator(
            value: _progress > 0 ? _progress : null,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _RestorePreviewProgressDialog extends StatefulWidget {
  const _RestorePreviewProgressDialog({required this.task});

  final Future<BackupPreview> Function(RestoreProgressCallback onProgress) task;

  @override
  State<_RestorePreviewProgressDialog> createState() =>
      _RestorePreviewProgressDialogState();
}

class _RestorePreviewProgressDialogState
    extends State<_RestorePreviewProgressDialog> {
  RestoreProgressStep _step = RestoreProgressStep.readingBackup;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _runTask();
  }

  Future<void> _runTask() async {
    try {
      final preview = await widget.task((step, progress) {
        if (!mounted) {
          return;
        }
        setState(() {
          _step = step;
          _progress = progress;
        });
      });

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(preview);
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      insetPadding: dialogInsetPadding(context),
      title: const Text('Reading Backup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _step.label,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.cardSpacing),
          LinearProgressIndicator(
            value: _progress > 0 ? _progress : null,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _RestoreApplyProgressDialog extends StatefulWidget {
  const _RestoreApplyProgressDialog({required this.task});

  final Future<void> Function(RestoreProgressCallback onProgress) task;

  @override
  State<_RestoreApplyProgressDialog> createState() =>
      _RestoreApplyProgressDialogState();
}

class _RestoreApplyProgressDialogState
    extends State<_RestoreApplyProgressDialog> {
  RestoreProgressStep _step = RestoreProgressStep.restoringData;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runTask();
  }

  Future<void> _runTask() async {
    try {
      await widget.task((step, progress) {
        if (!mounted) {
          return;
        }
        setState(() {
          _step = step;
          _progress = progress;
        });
      });

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      insetPadding: dialogInsetPadding(context),
      title: const Text('Restoring Backup'),
      content: _error != null
          ? Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _step.label,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.cardSpacing),
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
      actions: _error != null
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Close'),
              ),
            ]
          : null,
    );
  }
}
