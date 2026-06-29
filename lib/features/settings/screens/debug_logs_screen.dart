import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/logging_service.dart';
import '../../../models/app_log.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../theme/app_brand.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/form_padding.dart';

class DebugLogsScreen extends StatefulWidget {
  const DebugLogsScreen({super.key});

  @override
  State<DebugLogsScreen> createState() => _DebugLogsScreenState();
}

class _DebugLogsScreenState extends State<DebugLogsScreen> {
  List<AppLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _logs = LoggingService.instance.getLogs();
    });
  }

  Future<void> _refreshLogs() async {
    _loadLogs();
  }

  String _buildExportReport() {
    final buffer = StringBuffer()
      ..writeln('${AppBrand.name} Debug Logs')
      ..writeln();

    for (final log in _logs) {
      buffer.writeln(
        '${log.timestamp} | ${log.level} | ${log.category} | ${log.message}',
      );
    }

    return buffer.toString().trimRight();
  }

  Future<void> _exportLogs() async {
    if (_logs.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logs to export.')),
      );
      return;
    }

    await SharePlus.instance.share(ShareParams(text: _buildExportReport()));
  }

  Future<void> _confirmClearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: dialogInsetPadding(context),
        title: const Text('Clear debug logs?'),
        content: const Text(
          'All stored log entries will be permanently removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await LoggingService.instance.clearLogs();
    _loadLogs();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug logs cleared.')),
    );
  }

  ({Color background, Color foreground}) _levelColors(
    String level,
    ColorScheme colorScheme,
  ) {
    switch (level) {
      case LoggingService.levelInfo:
        return (
          background: colorScheme.primaryContainer,
          foreground: colorScheme.onPrimaryContainer,
        );
      case LoggingService.levelWarning:
        return (
          background: AppColors.statExpiringSoon.withValues(alpha: 0.18),
          foreground: AppColors.statExpiringSoon,
        );
      case LoggingService.levelError:
        return (
          background: colorScheme.errorContainer,
          foreground: colorScheme.onErrorContainer,
        );
      case LoggingService.levelDebug:
      default:
        return (
          background: colorScheme.surfaceContainerHighest,
          foreground: colorScheme.onSurfaceVariant,
        );
    }
  }

  Widget _levelBadge(String level, ColorScheme colorScheme) {
    final colors = _levelColors(level, colorScheme);

    return Chip(
      label: Text(
        level,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
      backgroundColor: colors.background,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide.none,
    );
  }

  Widget _logCard(AppLog log, ColorScheme colorScheme) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    log.timestamp,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                _levelBadge(log.level, colorScheme),
              ],
            ),
            const SizedBox(height: AppSpacing.fieldLabelGap),
            Text(
              log.category,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.fieldLabelGap),
            Text(
              log.message,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export Logs',
            onPressed: _exportLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear Logs',
            onPressed: _confirmClearLogs,
          ),
        ],
      ),
      body: SafeArea(
        child: _logs.isEmpty
            ? EmptyStateWidget(
                icon: EmptyStateWidget.mutedIcon(
                  context,
                  Icons.receipt_long_outlined,
                ),
                title: 'No logs yet',
                subtitle: 'Application events will appear here.',
              )
            : RefreshIndicator(
                onRefresh: _refreshLogs,
                child: ListView.builder(
                  padding: listScrollPadding(context),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < _logs.length - 1
                            ? AppSpacing.cardSpacing
                            : 0,
                      ),
                      child: _logCard(log, colorScheme),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
