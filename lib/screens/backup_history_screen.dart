import 'dart:io';

import 'package:flutter/material.dart';

import '../models/backup_history_entry.dart';
import '../core/services/logging_service.dart';
import '../services/backup_history_service.dart';
import '../services/backup_service.dart';
import '../shared/widgets/empty_state_widget.dart';
import '../theme/app_spacing.dart';
import '../utils/app_snackbar.dart';
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
    final stopwatch = Stopwatch()..start();
    final entries = await _historyService.getBackupHistory();
    stopwatch.stop();
    LoggingService.instance.logPerf(
      'backup_history_load',
      stopwatch.elapsedMilliseconds,
      metadata: {'entries': entries.length},
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  bool _fileExists(BackupHistoryEntry entry) {
    if (entry.filePath.isEmpty) {
      return false;
    }
    return File(entry.filePath).existsSync();
  }

  bool _canShare(BackupHistoryEntry entry) => _fileExists(entry);

  Future<void> _shareBackup(BackupHistoryEntry entry) async {
    final file = File(entry.filePath);
    if (!await file.exists()) {
      if (!mounted) {
        return;
      }
      final message = entry.isCloud
          ? 'Cloud backups must be downloaded from ${entry.displayDestination} to share'
          : 'Backup file no longer available on this device';
      AppSnackBar.show(context, message);
      return;
    }

    await BackupService.instance.shareBackupFile(file);
  }

  Future<void> _confirmDelete(BackupHistoryEntry entry) async {
    final deleteMessage = entry.isLocal
        ? 'Remove "${entry.fileName}" from backup history and delete the local backup file from this device?'
        : 'Remove "${entry.fileName}" from backup history? '
            'The file will remain on ${entry.displayDestination}.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: dialogInsetPadding(context),
        title: const Text('Delete backup?'),
        content: Text(deleteMessage),
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

    await _historyService.deleteEntry(entry);
    await _loadHistory();

    if (!mounted) {
      return;
    }

    final snackMessage = entry.isLocal
        ? 'Backup removed from history and device'
        : 'Backup removed from history (${entry.displayDestination} file unchanged)';
    AppSnackBar.show(context, snackMessage);
  }

  List<_TimelineItem> _buildTimelineItems() {
    final items = <_TimelineItem>[];
    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      final showDateHeader =
          i == 0 || !isSameBackupDay(entry.createdAt, _entries[i - 1].createdAt);
      if (showDateHeader) {
        items.add(_TimelineItem.dateHeader(entry.createdAt));
      }
      items.add(
        _TimelineItem.entry(
          entry: entry,
          isFirstInSection: showDateHeader,
          isLast: i == _entries.length - 1 ||
              !isSameBackupDay(entry.createdAt, _entries[i + 1].createdAt),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final timelineItems = _entries.isEmpty ? <_TimelineItem>[] : _buildTimelineItems();

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
                        'Successful local and cloud backups appear here after you create one.',
                    semanticLabel:
                        'No backups recorded yet. Successful local and cloud backups appear here after you create one.',
                  )
                : ListView.builder(
                    padding: listScrollPadding(
                      context,
                      top: AppSpacing.fieldLabelGap,
                    ),
                    itemCount: timelineItems.length,
                    itemBuilder: (context, index) {
                      final item = timelineItems[index];
                      if (item.isDateHeader) {
                        return _DateHeader(date: item.date!);
                      }
                      return _BackupTimelineTile(
                        entry: item.entry!,
                        isFirstInSection: item.isFirstInSection,
                        isLastInSection: item.isLast,
                        fileAvailable: _fileExists(item.entry!),
                        canShare: _canShare(item.entry!),
                        onShare: () => _shareBackup(item.entry!),
                        onDelete: () => _confirmDelete(item.entry!),
                      );
                    },
                  ),
      ),
    );
  }
}

class _TimelineItem {
  const _TimelineItem._({
    this.date,
    this.entry,
    this.isFirstInSection = false,
    this.isLast = false,
  });

  factory _TimelineItem.dateHeader(DateTime date) {
    return _TimelineItem._(date: date);
  }

  factory _TimelineItem.entry({
    required BackupHistoryEntry entry,
    required bool isFirstInSection,
    required bool isLast,
  }) {
    return _TimelineItem._(
      entry: entry,
      isFirstInSection: isFirstInSection,
      isLast: isLast,
    );
  }

  final DateTime? date;
  final BackupHistoryEntry? entry;
  final bool isFirstInSection;
  final bool isLast;

  bool get isDateHeader => date != null;
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.sectionSpacing,
        bottom: AppSpacing.fieldLabelGap,
      ),
      child: Text(
        formatBackupDateHeader(date),
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BackupTimelineTile extends StatelessWidget {
  const _BackupTimelineTile({
    required this.entry,
    required this.isFirstInSection,
    required this.isLastInSection,
    required this.fileAvailable,
    required this.canShare,
    required this.onShare,
    required this.onDelete,
  });

  final BackupHistoryEntry entry;
  final bool isFirstInSection;
  final bool isLastInSection;
  final bool fileAvailable;
  final bool canShare;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nodeColor = entry.isCloud
        ? colorScheme.tertiary
        : colorScheme.primary;
    final nodeIcon = entry.isCloud ? Icons.cloud_done_outlined : Icons.phone_android_outlined;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Expanded(
                    child: isFirstInSection
                        ? const SizedBox.shrink()
                        : Center(
                            child: Container(
                              width: 2,
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: nodeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: nodeColor, width: 2),
                    ),
                    child: Icon(
                      nodeIcon,
                      size: 14,
                      color: nodeColor,
                    ),
                  ),
                  Expanded(
                    child: isLastInSection
                        ? const SizedBox.shrink()
                        : Center(
                            child: Container(
                              width: 2,
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.fieldLabelGap),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: isLastInSection
                      ? AppSpacing.sectionSpacing
                      : AppSpacing.cardSpacing,
                ),
                child: Card(
                  elevation: AppSpacing.cardElevation,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.cardBorderRadius,
                  ),
                  child: Padding(
                    padding: AppSpacing.cardInsets,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _TypeChip(entry: entry),
                                  const SizedBox(height: AppSpacing.fieldLabelGap),
                                  Text(
                                    entry.fileName,
                                    style: theme.textTheme.titleMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Share',
                              onPressed: canShare ? onShare : null,
                              icon: const Icon(Icons.share_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: onDelete,
                              icon: Icon(
                                Icons.delete_outline,
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.fieldLabelGap),
                        _MetaRow(
                          icon: Icons.schedule_outlined,
                          label: formatBackupDateTime(entry.createdAt),
                        ),
                        const SizedBox(height: 4),
                        _MetaRow(
                          icon: Icons.sd_storage_outlined,
                          label: formatFileSize(entry.fileSizeBytes),
                        ),
                        const SizedBox(height: 4),
                        _MetaRow(
                          icon: entry.isCloud
                              ? Icons.cloud_outlined
                              : Icons.folder_outlined,
                          label: entry.displayDestination,
                        ),
                        if (!fileAvailable && entry.isLocal) ...[
                          const SizedBox(height: AppSpacing.fieldLabelGap),
                          Text(
                            'File no longer on device',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.entry});

  final BackupHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = entry.isCloud
        ? colorScheme.tertiaryContainer
        : colorScheme.primaryContainer;
    final foreground = entry.isCloud
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(
        entry.storageTypeLabel,
        style: theme.textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
