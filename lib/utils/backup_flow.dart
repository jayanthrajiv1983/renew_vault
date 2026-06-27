import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../services/backup_history_service.dart';
import '../services/backup_service.dart';
import '../services/settings_service.dart';
import '../utils/form_padding.dart';
import '../widgets/backup_progress_dialog.dart';

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
      destination: null,
    );

    if (!context.mounted) {
      return;
    }

    await _promptAndShareBackup(context, file);
  } on Exception catch (error) {
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
