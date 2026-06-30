import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/google_drive_backup_service.dart';
import '../shared/widgets/empty_state_widget.dart';
import '../theme/app_spacing.dart';
import '../utils/app_snackbar.dart';
import '../utils/backup_flow.dart';
import '../utils/form_padding.dart';
import '../utils/format_helpers.dart';
import '../widgets/cloud_download_progress_dialog.dart';
import '../widgets/restore_progress_dialog.dart';

class GoogleDriveRestoreScreen extends StatefulWidget {
  const GoogleDriveRestoreScreen({super.key});

  @override
  State<GoogleDriveRestoreScreen> createState() =>
      _GoogleDriveRestoreScreenState();
}

class _GoogleDriveRestoreScreenState extends State<GoogleDriveRestoreScreen> {
  List<GoogleDriveBackupFile> _backups = [];
  GoogleDriveBackupFile? _selectedBackup;
  GoogleSignInAccount? _googleAccount;
  bool _isLoading = true;
  bool _isRestoring = false;
  bool _isSigningIn = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await GoogleDriveBackupService.instance.init();
    if (!mounted) {
      return;
    }
    setState(() {
      _googleAccount = GoogleDriveBackupService.instance.currentAccount;
    });
    await _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _selectedBackup = null;
    });

    try {
      if (_googleAccount == null) {
        final account = await GoogleDriveBackupService.instance.signIn();
        if (!mounted) {
          return;
        }
        setState(() => _googleAccount = account);
      }

      final backups =
          await GoogleDriveBackupService.instance.listEncryptedBackups();
      if (!mounted) {
        return;
      }
      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } on GoogleDriveBackupException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = error.message;
        _isLoading = false;
      });
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _signInToGoogle() async {
    if (_isSigningIn) {
      return;
    }
    setState(() => _isSigningIn = true);
    try {
      final account = await GoogleDriveBackupService.instance.signIn();
      if (!mounted) {
        return;
      }
      setState(() => _googleAccount = account);
      await _loadBackups();
    } on GoogleDriveBackupException catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.show(context, error.message);
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _restoreSelectedBackup() async {
    final selected = _selectedBackup;
    if (selected == null || _isRestoring) {
      return;
    }

    final confirmed = await showRestoreDataReplacementDialog(
      context,
      backupName: selected.name,
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isRestoring = true);
    try {
      final bytes = await showCloudDownloadProgressDialog(
        context,
        (onProgress) => GoogleDriveBackupService.instance
            .downloadEncryptedBackup(
          fileId: selected.id,
          onProgress: onProgress,
        ),
      );

      if (!mounted || bytes == null) {
        return;
      }

      await runEncryptedRestoreFromBytesFlow(context, bytes);
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final googleEmail = _googleAccount?.email;
    final busy = _isRestoring || _isSigningIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restore from Google Drive'),
        actions: [
          if (!_isLoading && _googleAccount != null)
            IconButton(
              onPressed: busy ? null : _loadBackups,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (googleEmail != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.cardPadding,
                  AppSpacing.fieldLabelGap,
                  AppSpacing.cardPadding,
                  0,
                ),
                child: Text(
                  'Signed in as $googleEmail',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Expanded(child: _buildBody(theme)),
            if (_selectedBackup != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: FilledButton.icon(
                  onPressed: busy ? null : _restoreSelectedBackup,
                  icon: _isRestoring
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.restore, size: 18),
                  label: const Text('Restore selected backup'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_googleAccount == null) {
      return EmptyStateWidget(
        icon: EmptyStateWidget.mutedIcon(context, Icons.cloud_outlined),
        title: 'Sign in to Google Drive',
        subtitle: 'View and restore encrypted backups from your Drive.',
        buttonText: 'Sign in with Google',
        onButtonPressed: _signInToGoogle,
        semanticLabel:
            'Sign in to Google Drive. View and restore encrypted backups from your Drive. Sign in with Google.',
      );
    }

    if (_loadError != null) {
      return EmptyStateWidget(
        icon: EmptyStateWidget.mutedIcon(context, Icons.error_outline),
        title: 'Could not load backups',
        subtitle: _loadError!,
        buttonText: 'Try again',
        onButtonPressed: _loadBackups,
        semanticLabel: 'Could not load backups. Try again.',
      );
    }

    if (_backups.isEmpty) {
      return EmptyStateWidget(
        icon: EmptyStateWidget.mutedIcon(context, Icons.cloud_off_outlined),
        title: 'No backups found',
        subtitle:
            'Upload an encrypted backup to the Renew Vault Backups folder in Google Drive.',
        semanticLabel:
            'No backups found. Upload an encrypted backup to Google Drive first.',
      );
    }

    return ListView.separated(
      padding: listScrollPadding(
        context,
        top: AppSpacing.fieldLabelGap,
      ),
      itemCount: _backups.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final backup = _backups[index];
        final isSelected = _selectedBackup?.id == backup.id;
        final subtitle = [
          formatBackupDateTime(backup.modifiedTime),
          formatFileSize(backup.sizeBytes),
        ].join(' · ');

        return ListTile(
          selected: isSelected,
          selectedTileColor: theme.colorScheme.primaryContainer.withValues(
            alpha: 0.35,
          ),
          leading: CircleAvatar(
            backgroundColor: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.backup_outlined,
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(
            backup.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                )
              : Icon(
                  Icons.circle_outlined,
                  color: theme.colorScheme.outline,
                ),
          onTap: _isRestoring
              ? null
              : () {
                  setState(() {
                    _selectedBackup = backup;
                  });
                },
        );
      },
    );
  }
}
