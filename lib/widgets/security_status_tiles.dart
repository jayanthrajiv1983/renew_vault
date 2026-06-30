import 'package:flutter/material.dart';

import '../services/security_audit_service.dart';
import '../theme/app_spacing.dart';

/// Informational security posture tiles for Settings → Privacy & Security.
class SecurityStatusTiles extends StatefulWidget {
  const SecurityStatusTiles({
    super.key,
    required this.appLockEnabled,
  });

  final bool appLockEnabled;

  @override
  State<SecurityStatusTiles> createState() => _SecurityStatusTilesState();
}

class _SecurityStatusTilesState extends State<SecurityStatusTiles> {
  SecurityStatusSnapshot? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void didUpdateWidget(covariant SecurityStatusTiles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appLockEnabled != widget.appLockEnabled) {
      _applyAppLockStatus();
    }
  }

  Future<void> _loadStatus() async {
    final status = await SecurityAuditService.instance.getStatusSnapshot();
    if (mounted) {
      setState(
        () => _status = status.copyWith(appLockEnabled: widget.appLockEnabled),
      );
    }
  }

  void _applyAppLockStatus() {
    final status = _status;
    if (status == null) {
      return;
    }
    setState(
      () => _status = status.copyWith(appLockEnabled: widget.appLockEnabled),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final theme = Theme.of(context);

    if (status == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.fieldLabelGap,
        ),
        child: const LinearProgressIndicator(minHeight: 2),
      );
    }

    return Column(
      children: [
        _SecurityStatusTile(
          label: 'App Lock Enabled',
          enabled: status.appLockEnabled,
          theme: theme,
        ),
        const Divider(height: 1),
        _SecurityStatusTile(
          label: 'Local Data Encrypted',
          enabled: status.localDataEncrypted,
          theme: theme,
        ),
        const Divider(height: 1),
        _SecurityStatusTile(
          label: 'Backups Encrypted',
          enabled: status.backupsEncrypted,
          theme: theme,
        ),
        const Divider(height: 1),
        _SecurityStatusTile(
          label: 'Cloud Backups Encrypted',
          enabled: status.cloudBackupsEncrypted,
          theme: theme,
        ),
      ],
    );
  }
}

class _SecurityStatusTile extends StatelessWidget {
  const _SecurityStatusTile({
    required this.label,
    required this.enabled,
    required this.theme,
  });

  final String label;
  final bool enabled;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? theme.colorScheme.primary : theme.colorScheme.outline;
    final icon = enabled ? Icons.check_circle : Icons.info_outline;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: Text(
        enabled ? 'Active' : 'Review',
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
