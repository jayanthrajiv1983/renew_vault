import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:encrypt/encrypt.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/services/logging_service.dart';
import '../models/backup_preview.dart';
import '../models/family_member.dart';
import '../models/ocr_correction.dart';
import '../models/renewal_item.dart';
import 'attachment_service.dart';
import 'category_migration_service.dart';
import 'family_service.dart';
import 'hive_encryption_service.dart';
import 'milestone_service.dart';
import 'ocr_correction_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';

class BackupValidationException implements Exception {
  BackupValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupCancelledException implements Exception {}

enum BackupProgressStep {
  creatingBackup('Creating Backup...'),
  encrypting('Encrypting Data...'),
  preparingFile('Preparing File...');

  const BackupProgressStep(this.label);

  final String label;
}

enum RestoreProgressStep {
  readingBackup('Reading Backup...'),
  decrypting('Decrypting...'),
  restoringData('Restoring Data...');

  const RestoreProgressStep(this.label);

  final String label;
}

typedef BackupProgressCallback = void Function(
  BackupProgressStep step,
  double progress,
);

typedef RestoreProgressCallback = void Function(
  RestoreProgressStep step,
  double progress,
);

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  static const supportedVersion = 1;
  static const rvbackupFormatVersion = 1;
  static const _magicBytes = [0x52, 0x56, 0x42, 0x4B]; // "RVBK"
  static const _backupJsonName = 'backup.json';

  Map<String, dynamic> buildBackupPayload() {
    return {
      'version': supportedVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'renewals': StorageService.instance
          .getAll()
          .map((item) => item.toJson())
          .toList(),
      'familyMembers': FamilyService.instance
          .getAll()
          .map((member) => member.toJson())
          .toList(),
      'settings': SettingsService.instance.getAll(),
      'ocrCorrections': OcrCorrectionService.instance
          .getAllCorrections()
          .map((correction) => correction.toJson())
          .toList(),
    };
  }

  /// Creates an encrypted `.rvbackup` file (ZIP payload + AES-256-CBC).
  Future<File> exportEncryptedBackup({
    BackupProgressCallback? onProgress,
  }) async {
    LoggingService.instance.logInfo('BACKUP', 'Backup started');
    onProgress?.call(BackupProgressStep.creatingBackup, 0.1);

    final zipBytes = await _createZipArchive(onProgress);

    onProgress?.call(BackupProgressStep.encrypting, 0.6);
    final encryptedBytes = await _encryptZipBytes(zipBytes);

    onProgress?.call(BackupProgressStep.preparingFile, 0.85);
    final directory = await _exportDirectory();
    final timestamp = _formatTimestamp();
    final file = File(
      p.join(directory.path, 'renewvault_backup_$timestamp.rvbackup'),
    );
    await file.writeAsBytes(encryptedBytes, flush: true);

    onProgress?.call(BackupProgressStep.preparingFile, 1.0);
    LoggingService.instance.logInfo('BACKUP', 'Backup completed');
    return file;
  }

  Future<void> shareBackupFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'application/octet-stream',
            name: p.basename(file.path),
          ),
        ],
        subject: 'Renew Vault Backup',
        text: 'Renew Vault encrypted backup',
      ),
    );
  }

  Future<FilePickerResult?> pickBackupFile({
    required List<String> allowedExtensions,
  }) async {
    return FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<BackupPreview> previewPickedBackup(
    FilePickerResult result, {
    RestoreProgressCallback? onProgress,
  }) async {
    if (result.files.isEmpty) {
      throw BackupValidationException('No file was selected.');
    }

    final file = result.files.single;
    final extension = file.extension?.toLowerCase();

    if (extension == 'rvbackup') {
      onProgress?.call(RestoreProgressStep.readingBackup, 0.1);
      final rawBytes = await _readPickedBytes(file);
      return previewRvbackupBytes(rawBytes, onProgress: onProgress);
    }

    if (extension == 'json') {
      onProgress?.call(RestoreProgressStep.readingBackup, 0.2);
      final data = await _readJsonBackupFromPicker(file);
      onProgress?.call(RestoreProgressStep.readingBackup, 1.0);
      return _buildPreviewFromData(data);
    }

    throw BackupValidationException(
      'Unsupported file type. Select a .rvbackup or .json backup file.',
    );
  }

  Future<void> restoreFromPreview(
    BackupPreview preview, {
    RestoreProgressCallback? onProgress,
  }) async {
    LoggingService.instance.logInfo('BACKUP', 'Restore started');
    try {
      onProgress?.call(RestoreProgressStep.restoringData, 0.1);

      validateBackup(preview.data);

      if (preview.archive != null) {
        onProgress?.call(RestoreProgressStep.restoringData, 0.35);
        await _restoreAttachmentsFromArchive(preview.archive!);
      }

      onProgress?.call(RestoreProgressStep.restoringData, 0.65);
      await applyBackup(preview.data, skipValidation: true);

      await CategoryMigrationService.instance.runMigrationIfNeeded();

      onProgress?.call(RestoreProgressStep.restoringData, 1.0);
      LoggingService.instance.logInfo('BACKUP', 'Restore completed');
    } on Exception {
      LoggingService.instance.logError('BACKUP', 'Restore failed');
      rethrow;
    }
  }

  /// Legacy helper — reads and fully decodes a picked backup in one step.
  Future<Map<String, dynamic>> pickAndReadBackup() async {
    final result = await pickBackupFile(
      allowedExtensions: const ['json', 'rvbackup'],
    );

    if (result == null || result.files.isEmpty) {
      throw BackupCancelledException();
    }

    final preview = await previewPickedBackup(result);
    if (preview.archive != null) {
      await _restoreAttachmentsFromArchive(preview.archive!);
    }
    return preview.data;
  }

  Future<BackupPreview> previewRvbackupBytes(
    List<int> rawBytes, {
    RestoreProgressCallback? onProgress,
  }) async {
    if (rawBytes.isEmpty) {
      throw BackupValidationException('Backup file is empty.');
    }

    onProgress?.call(RestoreProgressStep.readingBackup, 0.25);
    _validateRvbackupHeader(rawBytes);

    onProgress?.call(RestoreProgressStep.decrypting, 0.4);
    final decrypted = await _decryptRvbackupBytes(rawBytes);

    onProgress?.call(RestoreProgressStep.decrypting, 0.7);
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(decrypted);
    } on Exception {
      throw BackupValidationException(
        'Unable to read backup contents. The file may be corrupted.',
      );
    }
    final data = _extractBackupJsonFromArchive(archive);

    onProgress?.call(RestoreProgressStep.decrypting, 0.9);
    validateBackup(data);

    final preview = _buildPreviewFromData(data, archive: archive);
    onProgress?.call(RestoreProgressStep.decrypting, 1.0);
    return preview;
  }

  Future<Map<String, dynamic>> decodeRvbackupFile(List<int> rawBytes) async {
    final preview = await previewRvbackupBytes(rawBytes);
    await _restoreAttachmentsFromArchive(preview.archive!);
    return preview.data;
  }

  void validateBackup(Map<String, dynamic> data) {
    const requiredKeys = [
      'version',
      'exportedAt',
      'renewals',
      'familyMembers',
      'settings',
    ];

    for (final key in requiredKeys) {
      if (!data.containsKey(key)) {
        throw BackupValidationException('Missing required key: $key');
      }
    }

    final version = data['version'];
    if (version is! int || version != supportedVersion) {
      if (version is int && version > supportedVersion) {
        throw BackupValidationException(
          'Backup was created with a newer app version. '
          'Please update Renew Vault and try again.',
        );
      }
      throw BackupValidationException(
        'Unsupported backup version. Expected $supportedVersion.',
      );
    }

    final exportedAt = data['exportedAt'];
    if (exportedAt is! String || DateTime.tryParse(exportedAt) == null) {
      throw BackupValidationException('Invalid exportedAt timestamp.');
    }

    final renewals = data['renewals'];
    if (renewals is! List) {
      throw BackupValidationException('renewals must be an array.');
    }

    for (var i = 0; i < renewals.length; i++) {
      final entry = renewals[i];
      if (entry is! Map) {
        throw BackupValidationException('renewals[$i] must be an object.');
      }
      try {
        RenewalItem.fromJson(Map<String, dynamic>.from(entry));
      } catch (error) {
        throw BackupValidationException('Invalid renewal at index $i: $error');
      }
    }

    final familyMembers = data['familyMembers'];
    if (familyMembers is! List) {
      throw BackupValidationException('familyMembers must be an array.');
    }

    for (var i = 0; i < familyMembers.length; i++) {
      final entry = familyMembers[i];
      if (entry is! Map) {
        throw BackupValidationException('familyMembers[$i] must be an object.');
      }
      try {
        FamilyMember.fromJson(Map<String, dynamic>.from(entry));
      } catch (error) {
        throw BackupValidationException(
          'Invalid family member at index $i: $error',
        );
      }
    }

    final settings = data['settings'];
    if (settings is! Map) {
      throw BackupValidationException('settings must be an object.');
    }

    final ocrCorrections = data['ocrCorrections'];
    if (ocrCorrections != null && ocrCorrections is! List) {
      throw BackupValidationException('ocrCorrections must be an array.');
    }
  }

  Future<void> applyBackup(
    Map<String, dynamic> data, {
    bool skipValidation = false,
  }) async {
    if (!skipValidation) {
      validateBackup(data);
    }

    final renewals = (data['renewals'] as List)
        .map(
          (entry) => RenewalItem.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();

    final familyMembers = (data['familyMembers'] as List)
        .map(
          (entry) => FamilyMember.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();

    final settings = Map<String, dynamic>.from(data['settings'] as Map);

    await StorageService.instance.replaceAll(renewals);
    await FamilyService.instance.replaceAll(familyMembers);
    await SettingsService.instance.applySettings(settings);
    await _applyOcrCorrections(data['ocrCorrections']);
    await MilestoneService.instance.syncPassedMilestones(renewals.length);
  }

  Future<void> _applyOcrCorrections(dynamic raw) async {
    if (raw is! List) {
      return;
    }

    final corrections = raw
        .whereType<Map>()
        .map(
          (entry) => OcrCorrection.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();
    await OcrCorrectionService.instance.replaceAll(corrections);
  }

  Future<List<int>> _createZipArchive(BackupProgressCallback? onProgress) async {
    final archive = Archive();

    final payload = buildBackupPayload();
    final jsonBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    archive.addFile(
      ArchiveFile(_backupJsonName, jsonBytes.length, jsonBytes),
    );

    onProgress?.call(BackupProgressStep.creatingBackup, 0.35);

    final renewals = StorageService.instance.getAll();
    final attachmentService = AttachmentService.instance;
    var processedAttachments = 0;
    var totalAttachments = 0;
    for (final renewal in renewals) {
      totalAttachments += renewal.attachments.length;
    }

    for (final renewal in renewals) {
      for (final attachment in renewal.attachments) {
        final file = await attachmentService.resolveAttachmentFile(attachment);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final zipPath = attachment.localPath.replaceAll('\\', '/');
          archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
        }

        processedAttachments++;
        if (totalAttachments > 0) {
          final attachmentProgress =
              0.35 + (0.25 * processedAttachments / totalAttachments);
          onProgress?.call(
            BackupProgressStep.creatingBackup,
            attachmentProgress,
          );
        }
      }
    }

    onProgress?.call(BackupProgressStep.creatingBackup, 0.55);
    return ZipEncoder().encode(archive);
  }

  Future<List<int>> _encryptZipBytes(List<int> zipBytes) async {
    final keyBytes =
        await HiveEncryptionService.instance.getOrCreateEncryptionKey();
    final key = Key(Uint8List.fromList(keyBytes));
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(zipBytes, iv: iv);

    final output = BytesBuilder(copy: false);
    output.add(_magicBytes);
    output.addByte(rvbackupFormatVersion);
    output.add(iv.bytes);
    output.add(encrypted.bytes);
    return output.toBytes();
  }

  Future<List<int>> _readPickedBytes(PlatformFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw BackupValidationException('Backup file is empty.');
    }
    return bytes;
  }

  void _validateRvbackupHeader(List<int> rawBytes) {
    if (rawBytes.length < _magicBytes.length + 1 + 16) {
      throw BackupValidationException('Invalid backup file (too short).');
    }

    for (var i = 0; i < _magicBytes.length; i++) {
      if (rawBytes[i] != _magicBytes[i]) {
        throw BackupValidationException(
          'Invalid backup file. This does not appear to be a Renew Vault backup.',
        );
      }
    }

    final formatVersion = rawBytes[_magicBytes.length];
    if (formatVersion > rvbackupFormatVersion) {
      throw BackupValidationException(
        'Backup was created with a newer app version. '
        'Please update Renew Vault and try again.',
      );
    }
    if (formatVersion != rvbackupFormatVersion) {
      throw BackupValidationException(
        'Unsupported backup format version: $formatVersion.',
      );
    }
  }

  Future<List<int>> _decryptRvbackupBytes(List<int> rawBytes) async {
    final ivOffset = _magicBytes.length + 1;
    const ivLength = 16;
    final iv = IV(
      Uint8List.fromList(rawBytes.sublist(ivOffset, ivOffset + ivLength)),
    );
    final ciphertext = rawBytes.sublist(ivOffset + ivLength);

    if (ciphertext.isEmpty) {
      throw BackupValidationException('Invalid backup file (no encrypted data).');
    }

    final keyBytes =
        await HiveEncryptionService.instance.getOrCreateEncryptionKey();
    final key = Key(Uint8List.fromList(keyBytes));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    try {
      return encrypter.decryptBytes(
        Encrypted(Uint8List.fromList(ciphertext)),
        iv: iv,
      );
    } on Exception {
      throw BackupValidationException(
        'Unable to decrypt backup. The file may be corrupted or '
        'was created on another device.',
      );
    }
  }

  Map<String, dynamic> _extractBackupJsonFromArchive(Archive archive) {
    ArchiveFile? backupJsonFile;
    for (final file in archive.files) {
      if (file.name == _backupJsonName && file.isFile) {
        backupJsonFile = file;
        break;
      }
    }

    if (backupJsonFile == null) {
      throw BackupValidationException('Backup archive missing backup.json.');
    }

    final jsonContent = utf8.decode(backupJsonFile.content as List<int>);
    try {
      final decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        throw BackupValidationException(
          'Backup file must contain a JSON object.',
        );
      }
      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw BackupValidationException('Backup contains invalid JSON data.');
    }
  }

  BackupPreview _buildPreviewFromData(
    Map<String, dynamic> data, {
    Archive? archive,
  }) {
    final renewals = data['renewals'];
    final familyMembers = data['familyMembers'];

    final renewalCount = renewals is List ? renewals.length : 0;
    final familyMemberCount =
        familyMembers is List ? familyMembers.length : 0;

    final attachmentCount = archive != null
        ? _countAttachmentsInArchive(archive)
        : _countAttachmentsInData(data);

    return BackupPreview(
      data: data,
      renewalCount: renewalCount,
      familyMemberCount: familyMemberCount,
      attachmentCount: attachmentCount,
      archive: archive,
    );
  }

  int _countAttachmentsInArchive(Archive archive) {
    var count = 0;
    for (final file in archive.files) {
      if (!file.isFile) {
        continue;
      }
      final normalizedName = file.name.replaceAll('\\', '/');
      if (normalizedName.startsWith('attachments/')) {
        count++;
      }
    }
    return count;
  }

  int _countAttachmentsInData(Map<String, dynamic> data) {
    final renewals = data['renewals'];
    if (renewals is! List) {
      return 0;
    }

    var count = 0;
    for (final entry in renewals) {
      if (entry is! Map) {
        continue;
      }
      final attachments = entry['attachments'];
      if (attachments is List) {
        count += attachments.length;
      }
    }
    return count;
  }

  Future<Map<String, dynamic>> _readJsonBackupFromPicker(PlatformFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw BackupValidationException('Backup file is empty.');
    }

    final contents = utf8.decode(bytes);

    try {
      final decoded = jsonDecode(contents);
      if (decoded is! Map<String, dynamic>) {
        throw BackupValidationException(
          'Backup file must contain a JSON object.',
        );
      }
      final data = Map<String, dynamic>.from(decoded);
      validateBackup(data);
      return data;
    } on FormatException {
      throw BackupValidationException('Backup contains invalid JSON data.');
    }
  }

  Future<void> _restoreAttachmentsFromArchive(Archive archive) async {
    final appDir = await getApplicationDocumentsDirectory();
    for (final file in archive.files) {
      if (!file.isFile || file.name == _backupJsonName) {
        continue;
      }

      final normalizedName = file.name.replaceAll('\\', '/');
      if (!normalizedName.startsWith('attachments/')) {
        continue;
      }

      final destination = File(p.join(appDir.path, normalizedName));
      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(file.content as List<int>);
    }
  }

  String _formatTimestamp() {
    return DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
  }

  Future<Directory> _exportDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final downloads = Directory(p.join(documents.path, 'downloads'));
    if (!await downloads.exists()) {
      await downloads.create(recursive: true);
    }
    return downloads;
  }
}
