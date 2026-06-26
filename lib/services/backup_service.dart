import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/family_member.dart';
import '../models/renewal_item.dart';
import 'family_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';

class BackupValidationException implements Exception {
  BackupValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupCancelledException implements Exception {}

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  static const supportedVersion = 1;

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
    };
  }

  Future<File> exportToFile() async {
    final payload = buildBackupPayload();
    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
    final directory = await _exportDirectory();
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/renewvault_backup_$timestamp.json');
    await file.writeAsString(jsonString);
    return file;
  }

  Future<void> shareBackupFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Renew Vault Backup',
      text: 'Renew Vault data backup',
    );
  }

  Future<Map<String, dynamic>> pickAndReadBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw BackupCancelledException();
    }

    final file = result.files.single;
    final bytes = file.bytes;
    final path = file.path;

    String contents;
    if (bytes != null) {
      contents = utf8.decode(bytes);
    } else if (path != null) {
      contents = await File(path).readAsString();
    } else {
      throw BackupValidationException('Unable to read the selected file.');
    }

    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic>) {
      throw BackupValidationException('Backup file must contain a JSON object.');
    }

    return Map<String, dynamic>.from(decoded);
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
  }

  Future<void> applyBackup(Map<String, dynamic> data) async {
    validateBackup(data);

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
  }

  Future<Directory> _exportDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final downloads = Directory('${documents.path}/downloads');
    if (!await downloads.exists()) {
      await downloads.create(recursive: true);
    }
    return downloads;
  }
}
