import '../core/services/logging_service.dart';
import 'attachment_encryption_service.dart';
import 'hive_encryption_service.dart';
import 'settings_service.dart';

/// Runs a one-time security posture check at startup and exposes status snapshots.
class SecurityAuditService {
  SecurityAuditService._();

  static final SecurityAuditService instance = SecurityAuditService._();

  static const _category = 'SECURITY';

  bool _ranThisSession = false;

  /// Runs attachment migration and logs audit completion once per app session.
  Future<void> runOnceAtStartup() async {
    if (_ranThisSession) {
      return;
    }
    _ranThisSession = true;

    await AttachmentEncryptionService.instance.migratePlainAttachmentsIfNeeded();
    await getStatusSnapshot();

    LoggingService.instance.logInfo(_category, 'Security audit completed');
  }

  /// Current security posture for Settings → Privacy & Security tiles.
  Future<SecurityStatusSnapshot> getStatusSnapshot() async {
    final hiveMigrationComplete =
        await HiveEncryptionService.instance.isMigrationComplete();
    final attachmentMigrationComplete =
        await AttachmentEncryptionService.instance.isMigrationComplete();

    return SecurityStatusSnapshot(
      appLockEnabled: SettingsService.instance.getAppLockEnabled(),
      localDataEncrypted:
          hiveMigrationComplete && attachmentMigrationComplete,
      backupsEncrypted: true,
      cloudBackupsEncrypted: true,
    );
  }
}

class SecurityStatusSnapshot {
  const SecurityStatusSnapshot({
    required this.appLockEnabled,
    required this.localDataEncrypted,
    required this.backupsEncrypted,
    required this.cloudBackupsEncrypted,
  });

  final bool appLockEnabled;
  final bool localDataEncrypted;
  final bool backupsEncrypted;
  final bool cloudBackupsEncrypted;

  SecurityStatusSnapshot copyWith({
    bool? appLockEnabled,
    bool? localDataEncrypted,
    bool? backupsEncrypted,
    bool? cloudBackupsEncrypted,
  }) {
    return SecurityStatusSnapshot(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      localDataEncrypted: localDataEncrypted ?? this.localDataEncrypted,
      backupsEncrypted: backupsEncrypted ?? this.backupsEncrypted,
      cloudBackupsEncrypted:
          cloudBackupsEncrypted ?? this.cloudBackupsEncrypted,
    );
  }
}
