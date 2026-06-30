import 'dart:io';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/backup_history_entry.dart';
import 'hive_encryption_service.dart';

class BackupHistoryService {
  BackupHistoryService._();

  static final BackupHistoryService instance = BackupHistoryService._();

  static const _boxName = 'settings';
  static const _historyKey = 'backupHistory';
  static const maxEntries = 20;

  static const _uuid = Uuid();

  Future<Box> _getBox() => HiveEncryptionService.instance.openBox(_boxName);

  Future<void> record({
    required String fileName,
    required String filePath,
    required int fileSizeBytes,
    String? destination,
    BackupStorageType storageType = BackupStorageType.local,
    String? cloudFileId,
  }) async {
    final entry = BackupHistoryEntry(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      fileName: fileName,
      filePath: filePath,
      fileSizeBytes: fileSizeBytes,
      destination: destination,
      storageType: storageType,
      cloudFileId: cloudFileId,
    );
    await addEntry(entry);
  }

  Future<void> addEntry(BackupHistoryEntry entry) async {
    final box = await _getBox();
    final current = _readEntries(box);
    final updated = [entry, ...current];
    if (updated.length > maxEntries) {
      updated.removeRange(maxEntries, updated.length);
    }
    await box.put(
      _historyKey,
      updated.map((item) => item.toJson()).toList(),
    );
  }

  Future<List<BackupHistoryEntry>> getBackupHistory() async {
    final box = await _getBox();
    final entries = _readEntries(box);
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> deleteBackupHistoryEntry(String id) async {
    final box = await _getBox();
    final updated =
        _readEntries(box).where((entry) => entry.id != id).toList();
    await box.put(
      _historyKey,
      updated.map((item) => item.toJson()).toList(),
    );
  }

  /// Removes a history entry and, for local backups, deletes the file on device.
  ///
  /// Cloud backup files on Google Drive are not deleted — only the history
  /// record is removed.
  Future<void> deleteEntry(BackupHistoryEntry entry) async {
    if (entry.isLocal && entry.filePath.isNotEmpty) {
      final file = File(entry.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await deleteBackupHistoryEntry(entry.id);
  }

  Future<void> updateDestination(String id, String? destination) async {
    final box = await _getBox();
    final entries = _readEntries(box);
    final index = entries.indexWhere((entry) => entry.id == id);
    if (index < 0) {
      return;
    }

    entries[index] = entries[index].copyWith(destination: destination);
    await box.put(
      _historyKey,
      entries.map((item) => item.toJson()).toList(),
    );
  }

  List<BackupHistoryEntry> _readEntries(Box box) {
    final value = box.get(_historyKey);
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map(
          (entry) => BackupHistoryEntry.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .where((entry) => entry.id.isNotEmpty)
        .toList();
  }
}
