import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/renewal_item.dart';
import 'attachment_service.dart';
import 'hive_encryption_service.dart';
import 'notification_service.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const _boxName = 'renewals';
  static const _uuid = Uuid();

  Box? _box;

  Future<void> init() async {
    _box = await HiveEncryptionService.instance.openBox(_boxName);
  }

  List<RenewalItem> getAll() {
    final box = _box;
    if (box == null || box.isEmpty) {
      return [];
    }

    final items = box.values
        .map(
          (value) => RenewalItem.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();

    items.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
    return items;
  }

  Future<void> saveToBox(RenewalItem item) async {
    await _box!.put(item.id, item.toJson());
  }

  Future<void> save(RenewalItem item) async {
    final updated = await NotificationService.instance.scheduleRenewalReminders(item);
    await saveToBox(updated);
  }

  Future<void> update(RenewalItem item) async {
    await save(item);
  }

  Future<RenewalItem?> getById(String id) async {
    final value = _box?.get(id);
    if (value == null) {
      return null;
    }
    return RenewalItem.fromJson(Map<String, dynamic>.from(value as Map));
  }

  Future<void> delete(String id) async {
    final item = await getById(id);
    if (item != null) {
      await permanentlyDeleteStashedItem(item);
    } else {
      await _box!.delete(id);
    }
  }

  /// Removes an item from Hive and cancels reminders without deleting attachments.
  /// Used while a delete is pending undo.
  Future<void> stashDelete(String id) async {
    final item = await getById(id);
    if (item != null) {
      await NotificationService.instance.cancelRenewalReminders(item);
    }
    await _box!.delete(id);
  }

  /// Permanently removes a stashed or stored item, including attachments.
  Future<void> permanentlyDeleteStashedItem(RenewalItem item) async {
    await NotificationService.instance.cancelRenewalReminders(item);
    await AttachmentService.instance.deleteAllAttachmentFiles(item);
    if (_box!.containsKey(item.id)) {
      await _box!.delete(item.id);
    }
  }

  /// Creates a copy of [source] with a new id, title suffixed with " (Copy)",
  /// fresh notification ids, and duplicated attachment files on disk.
  Future<RenewalItem> duplicate(RenewalItem source) async {
    final newId = _uuid.v4();
    var duplicateItem = source.copyWith(
      id: newId,
      title: '${source.title} (Copy)',
      notificationIds: const {},
      reminderDays: List<int>.from(source.reminderDays),
      metadata: Map<String, dynamic>.from(source.metadata),
      attachments: const [],
    );

    for (final attachment in source.attachments) {
      final sourceFile =
          await AttachmentService.instance.resolveAttachmentFile(attachment);
      if (!await sourceFile.exists()) {
        continue;
      }

      final result = await AttachmentService.instance.saveFile(
        item: duplicateItem,
        sourceFile: sourceFile,
        fileType: attachment.fileType,
        preferredFileName: attachment.fileName,
      );
      duplicateItem = result.item;
    }

    await save(duplicateItem);
    return duplicateItem;
  }

  Future<void> replaceAll(List<RenewalItem> items) async {
    for (final item in getAll()) {
      await NotificationService.instance.cancelRenewalReminders(item);
    }

    await _box!.clear();

    for (final item in items) {
      final updated = await NotificationService.instance.scheduleRenewalReminders(item);
      await saveToBox(updated);
    }
  }
}
