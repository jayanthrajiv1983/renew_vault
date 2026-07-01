import 'package:flutter/material.dart';

import '../core/theme/design_system.dart';
import '../services/google_drive_backup_service.dart';
import '../utils/form_padding.dart';

Future<List<int>?> showCloudDownloadProgressDialog(
  BuildContext context,
  Future<List<int>> Function(CloudUploadProgressCallback onProgress) task,
) async {
  return showDialog<List<int>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _CloudDownloadProgressDialog(task: task),
  );
}

class _CloudDownloadProgressDialog extends StatefulWidget {
  const _CloudDownloadProgressDialog({required this.task});

  final Future<List<int>> Function(CloudUploadProgressCallback onProgress) task;

  @override
  State<_CloudDownloadProgressDialog> createState() =>
      _CloudDownloadProgressDialogState();
}

class _CloudDownloadProgressDialogState
    extends State<_CloudDownloadProgressDialog> {
  double _progress = 0;
  String _label = 'Preparing...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _runTask();
  }

  Future<void> _runTask() async {
    try {
      final bytes = await widget.task((progress, label) {
        if (!mounted) {
          return;
        }
        setState(() {
          _progress = progress;
          _label = label;
        });
      });

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(bytes);
    } on GoogleDriveBackupException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
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
      title: const Text('Download from Google Drive'),
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
                  _label,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppDesignTokens.space16),
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress.clamp(0.0, 1.0) : null,
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
