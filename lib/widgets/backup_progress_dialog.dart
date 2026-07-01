import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/design_system.dart';
import '../services/backup_service.dart';
import '../utils/form_padding.dart';

/// Material 3 dialog showing backup creation progress with step labels.
Future<File?> showBackupProgressDialog(
  BuildContext context,
  Future<File> Function(BackupProgressCallback onProgress) task,
) async {
  return showDialog<File>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _BackupProgressDialog(task: task),
  );
}

class _BackupProgressDialog extends StatefulWidget {
  const _BackupProgressDialog({required this.task});

  final Future<File> Function(BackupProgressCallback onProgress) task;

  @override
  State<_BackupProgressDialog> createState() => _BackupProgressDialogState();
}

class _BackupProgressDialogState extends State<_BackupProgressDialog> {
  BackupProgressStep _step = BackupProgressStep.creatingBackup;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runTask();
  }

  Future<void> _runTask() async {
    try {
      final file = await widget.task((step, progress) {
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
      Navigator.of(context).pop(file);
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
      title: const Text('Creating Backup'),
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
                const SizedBox(height: AppDesignTokens.space16),
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
      actions: _error != null
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ]
          : null,
    );
  }
}
