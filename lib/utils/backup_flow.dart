import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../core/services/logging_service.dart';
import '../core/services/crashlytics_service.dart';
import '../models/backup_integrity_result.dart';
import '../models/backup_preview.dart';
import '../models/backup_history_entry.dart';
import '../services/backup_history_service.dart';
import '../services/backup_integrity_service.dart';
import '../services/backup_service.dart';
import '../services/settings_service.dart';
import '../shared/widgets/success_overlay.dart';
import '../utils/form_padding.dart';
import '../widgets/backup_progress_dialog.dart';
import '../widgets/restore_progress_dialog.dart';

/// Runs encrypted backup creation, records success, and prompts to share.
Future<void> runEncryptedBackupFlow(BuildContext context) async {
  try {
    final file = await showBackupProgressDialog(
      context,
      (onProgress) => BackupService.instance.exportEncryptedBackup(
        onProgress: onProgress,
      ),
    );

    if (!context.mounted || file == null) {
      return;
    }

    await SettingsService.instance.recordSuccessfulBackup();

    await BackupHistoryService.instance.record(
      fileName: p.basename(file.path),
      filePath: file.path,
      fileSizeBytes: await file.length(),
      destination: 'This device',
      storageType: BackupStorageType.local,
    );

    if (!context.mounted) {
      return;
    }

    await _promptAndShareBackup(context, file);

    if (!context.mounted) {
      return;
    }

    await SuccessOverlay.show(
      context,
      message: 'Backup complete',
    );
  } on Exception catch (error, stack) {
    LoggingService.instance.logError(
      CrashlyticsService.featureBackup,
      'Backup failed',
      exception: error,
      stackTrace: stack,
      operation: 'Export Failed',
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup failed: $error')),
    );
  }
}

Future<void> _promptAndShareBackup(BuildContext context, File file) async {
  final shouldShare = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      insetPadding: dialogInsetPadding(context),
      title: const Text('Backup Ready'),
      content: const Text('Choose where to save your encrypted backup.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Share'),
        ),
      ],
    ),
  );

  if (shouldShare != true || !context.mounted) {
    return;
  }

  await BackupService.instance.shareBackupFile(file);
}

void _logBackupIntegrityResult(BackupIntegrityResult result) {
  if (result.isSuccess) {
    LoggingService.instance.logInfo(
      'BACKUP',
      'Integrity verification passed',
    );
    return;
  }

  final check = result.failedCheck?.name ?? 'unknown';
  LoggingService.instance.logWarning(
    'BACKUP',
    'Integrity verification failed: check=$check',
  );
}

/// Runs integrity verification with progress and result dialogs.
/// Returns a [BackupPreview] when verified; null when verification fails.
Future<BackupPreview?> verifyBackupBeforeRestore(
  BuildContext context,
  Future<BackupIntegrityResult> Function(RestoreProgressCallback onProgress)
      verify,
) async {
  final integrityResult = await showBackupVerificationProgressDialog(
    context,
    verify,
  );

  if (!context.mounted || integrityResult == null) {
    return null;
  }

  _logBackupIntegrityResult(integrityResult);

  await showBackupVerificationResultDialog(
    context,
    success: integrityResult.isSuccess,
  );

  if (!context.mounted || !integrityResult.isSuccess) {
    return null;
  }

  return integrityResult.preview;
}

/// Reads, verifies, confirms, and applies an encrypted backup from raw bytes.
Future<bool> runEncryptedRestoreFromBytesFlow(
  BuildContext context,
  List<int> rawBytes,
) async {
  try {
    final preview = await verifyBackupBeforeRestore(
      context,
      (onProgress) => BackupIntegrityService.instance.verifyRvbackupBytes(
        rawBytes,
        onProgress: onProgress,
      ),
    );

    if (!context.mounted || preview == null) {
      return false;
    }

    final confirmed = await showRestoreSummaryDialog(context, preview);
    if (confirmed != true || !context.mounted) {
      return false;
    }

    final restored = await showRestoreApplyProgressDialog(
      context,
      (onProgress) => BackupService.instance.restoreFromPreview(
        preview,
        onProgress: onProgress,
      ),
    );

    if (!restored || !context.mounted) {
      return false;
    }

    await SuccessOverlay.show(
      context,
      message: 'Restore complete',
    );
    return true;
  } on BackupValidationException catch (error, stack) {
    LoggingService.instance.logError(
      CrashlyticsService.featureRestore,
      'Restore validation failed',
      exception: error,
      stackTrace: stack,
      operation: 'Restore Failed',
    );
    if (!context.mounted) {
      return false;
    }
    await showRestoreErrorDialog(context, message: error.message);
    return false;
  } on Exception catch (error, stack) {
    LoggingService.instance.logError(
      CrashlyticsService.featureRestore,
      'Restore failed',
      exception: error,
      stackTrace: stack,
      operation: 'Restore Failed',
    );
    if (!context.mounted) {
      return false;
    }
    await showRestoreErrorDialog(
      context,
      message: 'Restore failed: $error',
    );
    return false;
  }
}
