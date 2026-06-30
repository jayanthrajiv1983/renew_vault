import 'backup_preview.dart';

/// Individual integrity checks run before restore.
enum BackupIntegrityCheck {
  fileReadable,
  encryptionValid,
  jsonValid,
  requiredFields,
}

/// Outcome of pre-restore backup integrity verification.
class BackupIntegrityResult {
  const BackupIntegrityResult._({
    required this.isSuccess,
    this.failedCheck,
    this.preview,
  });

  final bool isSuccess;
  final BackupIntegrityCheck? failedCheck;
  final BackupPreview? preview;

  factory BackupIntegrityResult.success(BackupPreview preview) {
    return BackupIntegrityResult._(
      isSuccess: true,
      preview: preview,
    );
  }

  factory BackupIntegrityResult.failure(BackupIntegrityCheck check) {
    return BackupIntegrityResult._(
      isSuccess: false,
      failedCheck: check,
    );
  }
}
