import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';

import '../models/backup_integrity_result.dart';
import 'backup_service.dart';

class BackupIntegrityService {
  BackupIntegrityService._();

  static final BackupIntegrityService instance = BackupIntegrityService._();

  Future<BackupIntegrityResult> verifyPickedBackup(
    FilePickerResult result, {
    RestoreProgressCallback? onProgress,
  }) async {
    if (result.files.isEmpty) {
      return BackupIntegrityResult.failure(BackupIntegrityCheck.fileReadable);
    }

    final file = result.files.single;
    final extension = file.extension?.toLowerCase();

    List<int> rawBytes;
    try {
      rawBytes = await file.readAsBytes();
    } on Exception {
      return BackupIntegrityResult.failure(BackupIntegrityCheck.fileReadable);
    }

    if (extension == 'rvbackup') {
      return verifyRvbackupBytes(rawBytes, onProgress: onProgress);
    }

    if (extension == 'json') {
      return verifyJsonBytes(rawBytes, onProgress: onProgress);
    }

    return BackupIntegrityResult.failure(BackupIntegrityCheck.fileReadable);
  }

  Future<BackupIntegrityResult> verifyRvbackupBytes(
    List<int> rawBytes, {
    RestoreProgressCallback? onProgress,
  }) async {
    onProgress?.call(RestoreProgressStep.readingBackup, 0.1);

    if (rawBytes.isEmpty) {
      return BackupIntegrityResult.failure(BackupIntegrityCheck.fileReadable);
    }

    try {
      BackupService.instance.checkRvbackupHeader(rawBytes);
    } on BackupValidationException {
      return BackupIntegrityResult.failure(BackupIntegrityCheck.fileReadable);
    }

    onProgress?.call(RestoreProgressStep.decrypting, 0.35);

    List<int> decrypted;
    try {
      decrypted = await BackupService.instance.decryptRvbackup(rawBytes);
    } on BackupValidationException {
      return BackupIntegrityResult.failure(BackupIntegrityCheck.encryptionValid);
    }

    onProgress?.call(RestoreProgressStep.decrypting, 0.55);

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(decrypted);
    } on Exception {
      return BackupIntegrityResult.failure(BackupIntegrityCheck.jsonValid);
    }

    Map<String, dynamic> data;
    try {
      data = BackupService.instance.parseBackupJsonFromArchive(archive);
    } on BackupValidationException catch (error) {
      if (_isJsonParseFailure(error)) {
        return BackupIntegrityResult.failure(BackupIntegrityCheck.jsonValid);
      }
      return BackupIntegrityResult.failure(BackupIntegrityCheck.requiredFields);
    }

    onProgress?.call(RestoreProgressStep.decrypting, 0.8);

    try {
      BackupService.instance.validateBackup(data);
    } on BackupValidationException {
      return BackupIntegrityResult.failure(BackupIntegrityCheck.requiredFields);
    }

    onProgress?.call(RestoreProgressStep.decrypting, 1.0);
    return BackupIntegrityResult.success(
      BackupService.instance.buildPreviewFromData(data, archive: archive),
    );
  }

  Future<BackupIntegrityResult> verifyJsonBytes(
    List<int> rawBytes, {
    RestoreProgressCallback? onProgress,
  }) async {
    onProgress?.call(RestoreProgressStep.readingBackup, 0.2);

    if (rawBytes.isEmpty) {
      return BackupIntegrityResult.failure(BackupIntegrityCheck.fileReadable);
    }

    onProgress?.call(RestoreProgressStep.decrypting, 0.5);

    Map<String, dynamic> data;
    try {
      final contents = utf8.decode(rawBytes);
      final decoded = jsonDecode(contents);
      if (decoded is! Map<String, dynamic>) {
        return BackupIntegrityResult.failure(BackupIntegrityCheck.jsonValid);
      }
      data = Map<String, dynamic>.from(decoded);
    } on FormatException {
      return BackupIntegrityResult.failure(BackupIntegrityCheck.jsonValid);
    } on Exception {
      return BackupIntegrityResult.failure(BackupIntegrityCheck.fileReadable);
    }

    onProgress?.call(RestoreProgressStep.decrypting, 0.8);

    try {
      BackupService.instance.validateBackup(data);
    } on BackupValidationException {
      return BackupIntegrityResult.failure(BackupIntegrityCheck.requiredFields);
    }

    onProgress?.call(RestoreProgressStep.decrypting, 1.0);
    return BackupIntegrityResult.success(
      BackupService.instance.buildPreviewFromData(data),
    );
  }

  bool _isJsonParseFailure(BackupValidationException error) {
    final message = error.message.toLowerCase();
    return message.contains('json') ||
        message.contains('backup.json') ||
        message.contains('json object');
  }
}
