import 'dart:io';

import 'package:flutter/material.dart';

import '../models/backup_history_entry.dart';
import '../services/backup_history_service.dart';
import '../services/backup_service.dart';
import '../shared/widgets/empty_state_widget.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import '../utils/format_helpers.dart';

class BackupHistoryScreen extends StatefulWidget {
  const BackupHistoryScreen({super.key});

  @override
  State<BackupHistoryScreen> createState() => _BackupHistoryScreenState();
}

class _BackupHistoryScreenState extends State<BackupHistoryScreen> {
  final _historyService = BackupHistoryService.instance;

  List<BackupHistoryEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final entries = await _historyService.getBackupHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  bool _fileExists(BackupHistoryEntry entry) {
    return File(entry.filePath).existsSync();
  }

  void _openDetails(BackupHistoryEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final fileAvailable = _fileExists(entry);

        return SafeArea(
          child: SingleChildScrollView(
            padding: bottomSheetPadding(sheetContext),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Backup Details',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sectionSpacing),
                _detailRow(
                  sheetContext,
                  label: 'Backup Date',
                  value: formatBackupDateTime(entry.createdAt),
                ),
                _detailRow(
                  sheetContext,
                  label: 'File Name',
                  value: entry.fileName,
                ),
                _detailRow(
                  sheetContext,
                  label: 'File Size',
                  value: formatFileSize(entry.fileSizeBytes),
                ),
                _detailRow(
                  sheetContext,
                  label: 'Destination',
                  value: entry.destination ?? 'Not recorded',
                ),
                _detailRow(
                  sheetContext,
                  label: 'File Location',
                  value: entry.filePath,
                ),
                _detailRow(
                  sheetContext,
                  label: 'File Status',
                  value: fileAvailable ? 'Available on device' : 'No longer available',
                ),
                const SizedBox(height: AppSpacing.sectionSpacing),
                FilledButton.icon(
                  onPressed: fileAvailable
                      ? () => _shareBackup(sheetContext, entry)
                      : null,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share Again'),
                ),
                const SizedBox(height: AppSpacing.fieldLabelGap),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _confirmDelete(entry);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete History Entry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.fieldLabelGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Future<void> _shareBackup(
    BuildContext context,
    BackupHistoryEntry entry,
  ) async {
    final file = File(entry.filePath);
    if (!await file.exists()) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup file no longer available')),
      );
      return;
    }

    await BackupService.instance.shareBackupFile(file);
  }

  Future<void> _confirmDelete(BackupHistoryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: dialogInsetPadding(context),
        title: const Text('Delete history entry?'),
        content: Text(
          'Remove "${entry.fileName}" from backup history? '
          'The backup file on your device will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _historyService.deleteBackupHistoryEntry(entry.id);
    await _loadHistory();

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup history entry removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup History'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
                ? EmptyStateWidget(
                    icon: EmptyStateWidget.mutedIcon(context, Icons.history),
                    title: 'No backups recorded yet',
                    subtitle:
                        'Successful backups appear here after you create one from Settings.',
                    semanticLabel:
                        'No backups recorded yet. Successful backups appear here after you create one from Settings.',
                  )
                : ListView.separated(
                    padding: listScrollPadding(
                      context,
                      top: AppSpacing.fieldLabelGap,
                    ),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      final fileAvailable = _fileExists(entry);
                      final subtitle = [
                        formatBackupDateTime(entry.createdAt),
                        formatFileSize(entry.fileSizeBytes),
                        if (!fileAvailable) 'File unavailable',
                      ].join(' · ');

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.backup_outlined,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          entry.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(subtitle),
                        trailing: PopupMenuButton<_BackupHistoryAction>(
                          onSelected: (action) async {
                            switch (action) {
                              case _BackupHistoryAction.viewDetails:
                                _openDetails(entry);
                              case _BackupHistoryAction.share:
                                await _shareBackup(context, entry);
                              case _BackupHistoryAction.delete:
                                await _confirmDelete(entry);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: _BackupHistoryAction.viewDetails,
                              child: Text('View details'),
                            ),
                            PopupMenuItem(
                              value: _BackupHistoryAction.share,
                              enabled: fileAvailable,
                              child: const Text('Share again'),
                            ),
                            const PopupMenuItem(
                              value: _BackupHistoryAction.delete,
                              child: Text('Delete entry'),
                            ),
                          ],
                        ),
                        onTap: () => _openDetails(entry),
                      );
                    },
                  ),
      ),
    );
  }
}

enum _BackupHistoryAction {
  viewDetails,
  share,
  delete,
}
