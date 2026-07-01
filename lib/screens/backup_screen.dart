import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/theme/design_system.dart';
import '../services/google_drive_backup_service.dart';
import '../services/settings_service.dart';
import '../shared/widgets/success_overlay.dart';
import '../theme/app_spacing.dart';
import '../utils/app_snackbar.dart';
import '../utils/backup_flow.dart';
import '../utils/format_helpers.dart';
import '../utils/form_padding.dart';
import '../widgets/cloud_upload_progress_dialog.dart';
import 'backup_history_screen.dart';
import 'google_drive_restore_screen.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isBackingUp = false;
  bool _isCloudUploading = false;
  bool _isSigningIn = false;
  GoogleSignInAccount? _googleAccount;

  @override
  void initState() {
    super.initState();
    SettingsService.instance.addListener(_onSettingsChanged);
    _loadGoogleAccount();
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadGoogleAccount() async {
    await GoogleDriveBackupService.instance.init();
    if (mounted) {
      setState(() {
        _googleAccount = GoogleDriveBackupService.instance.currentAccount;
      });
    }
  }

  Future<void> _backupData() async {
    setState(() => _isBackingUp = true);
    try {
      await runEncryptedBackupFlow(context);
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _signInToGoogle() async {
    setState(() => _isSigningIn = true);
    try {
      final account = await GoogleDriveBackupService.instance.signIn();
      if (mounted) {
        setState(() => _googleAccount = account);
      }
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

  Future<void> _signOutFromGoogle() async {
    await GoogleDriveBackupService.instance.signOut();
    if (mounted) {
      setState(() => _googleAccount = null);
    }
  }

  Future<void> _uploadToGoogleDrive() async {
    if (_googleAccount == null) {
      try {
        final account = await GoogleDriveBackupService.instance.signIn();
        if (!mounted) {
          return;
        }
        setState(() => _googleAccount = account);
      } on GoogleDriveBackupException catch (error) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
        return;
      }
    }

    setState(() => _isCloudUploading = true);
    try {
      await showCloudUploadProgressDialog(
        context,
        (onProgress) => GoogleDriveBackupService.instance.uploadEncryptedBackup(
          onProgress: onProgress,
        ),
      );

      if (!mounted) {
        return;
      }

      await SuccessOverlay.show(
        context,
        message: 'Backup successful',
      );
    } on GoogleDriveBackupException catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.show(context, error.message);
    } finally {
      if (mounted) {
        setState(() => _isCloudUploading = false);
      }
    }
  }

  Future<void> _openBackupHistoryScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const BackupHistoryScreen(),
      ),
    );
  }

  Future<void> _openGoogleDriveRestoreScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const GoogleDriveRestoreScreen(),
      ),
    );
    await _loadGoogleAccount();
  }

  Widget? _busyTrailing(bool busy) {
    if (!busy) {
      return null;
    }
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  String? _lastCloudBackupLabel() {
    final lastCloudBackup = SettingsService.instance.getLastCloudBackupAt();
    if (lastCloudBackup == null) {
      return null;
    }
    return 'Last cloud backup: ${formatBackupDateTime(lastCloudBackup)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastCloudBackupLabel = _lastCloudBackupLabel();
    final googleEmail = _googleAccount?.email;
    final cloudBusy = _isCloudUploading || _isSigningIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup'),
      ),
      body: SafeArea(
        child: ListView(
          padding: listScrollPadding(context),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: AppDesignTokens.cardListTilePadding,
                    titleAlignment: ListTileTitleAlignment.center,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.save,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: const Text('Backup Data'),
                    subtitle: const Text(
                      'Create encrypted backup and save or share via Drive, iCloud, email, etc.',
                    ),
                    trailing: _busyTrailing(_isBackingUp) ??
                        const Icon(Icons.chevron_right),
                    enabled: !_isBackingUp,
                    onTap: _isBackingUp ? null : _backupData,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: AppDesignTokens.cardListTilePadding,
                    titleAlignment: ListTileTitleAlignment.center,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.history,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: const Text('Backup History'),
                    subtitle: const Text('View past backups and share again'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openBackupHistoryScreen,
                  ),
                ],
              ),
            ),
            AppSpacing.gapSection,
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: AppDesignTokens.cardListTilePadding,
                    titleAlignment: ListTileTitleAlignment.center,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: const Text('Backup to Google Drive'),
                    subtitle: Text(
                      googleEmail == null
                          ? 'Sign in with Google to upload encrypted backups to your Drive.'
                          : 'Signed in as $googleEmail',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (lastCloudBackupLabel != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDesignTokens.space16 + 56,
                        0,
                        AppDesignTokens.space16,
                        AppDesignTokens.space8,
                      ),
                      child: Text(
                        lastCloudBackupLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDesignTokens.space16,
                      0,
                      AppDesignTokens.space16,
                      AppDesignTokens.space16,
                    ),
                    child: Wrap(
                      spacing: AppDesignTokens.space8,
                      runSpacing: AppDesignTokens.space8,
                      children: [
                        if (googleEmail == null)
                          FilledButton.icon(
                            onPressed: cloudBusy ? null : _signInToGoogle,
                            icon: _isSigningIn
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.login, size: 18),
                            label: const Text('Sign in with Google'),
                          )
                        else ...[
                          FilledButton.icon(
                            onPressed: cloudBusy ? null : _uploadToGoogleDrive,
                            icon: _isCloudUploading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload, size: 18),
                            label: const Text('Upload backup'),
                          ),
                          OutlinedButton(
                            onPressed: cloudBusy ? null : _signOutFromGoogle,
                            child: const Text('Sign out'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapSection,
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: AppDesignTokens.cardListTilePadding,
                    titleAlignment: ListTileTitleAlignment.center,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                      child: Icon(
                        Icons.cloud_download_outlined,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                    title: const Text('Restore from Google Drive'),
                    subtitle: const Text(
                      'Download and restore an encrypted backup from your Drive.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openGoogleDriveRestoreScreen,
                  ),
                ],
              ),
            ),
            AppSpacing.gapSection,
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignTokens.pagePaddingHorizontal,
              ),
              child: Text(
                'Regular backups help protect your item data if you change devices or reinstall the app.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
