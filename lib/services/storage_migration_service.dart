import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'hive_encryption_service.dart';

class StorageMigrationResult {
  const StorageMigrationResult._({
    required this.success,
    this.message,
    this.error,
  });

  final bool success;
  final String? message;
  final Object? error;

  factory StorageMigrationResult.success() {
    return const StorageMigrationResult._(success: true);
  }

  factory StorageMigrationResult.failure({
    required String message,
    Object? error,
  }) {
    return StorageMigrationResult._(
      success: false,
      message: message,
      error: error,
    );
  }
}

/// Migrates legacy unencrypted Hive boxes to AES-encrypted storage.
class StorageMigrationService {
  StorageMigrationService._();

  static final StorageMigrationService instance = StorageMigrationService._();

  final HiveEncryptionService _encryption = HiveEncryptionService.instance;

  Future<StorageMigrationResult> runMigrationIfNeeded() async {
    await _encryption.getOrCreateEncryptionKey();

    if (await _encryption.isMigrationComplete()) {
      return StorageMigrationResult.success();
    }

    final cipher = await _encryption.getCipher();

    for (final boxName in HiveEncryptionService.encryptedBoxNames) {
      final result = await _migrateBox(boxName, cipher);
      if (!result.success) {
        return result;
      }
    }

    await _encryption.markMigrationComplete();
    return StorageMigrationResult.success();
  }

  Future<StorageMigrationResult> _migrateBox(
    String boxName,
    HiveAesCipher cipher,
  ) async {
    if (!await Hive.boxExists(boxName)) {
      return StorageMigrationResult.success();
    }

    Box? unencryptedBox;
    try {
      unencryptedBox = await Hive.openBox(boxName);
      final data = Map<dynamic, dynamic>.from(unencryptedBox.toMap());
      await unencryptedBox.close();
      unencryptedBox = null;

      await Hive.deleteBoxFromDisk(boxName);

      final encryptedBox =
          await Hive.openBox(boxName, encryptionCipher: cipher);
      for (final entry in data.entries) {
        await encryptedBox.put(entry.key, entry.value);
      }
      await encryptedBox.close();

      if (kDebugMode) {
        debugPrint(
          'StorageMigrationService: migrated "$boxName" '
          '(${data.length} entries)',
        );
      }
      return StorageMigrationResult.success();
    } catch (unencryptedError) {
      if (unencryptedBox != null && unencryptedBox.isOpen) {
        await unencryptedBox.close();
      }

      try {
        final encryptedBox =
            await Hive.openBox(boxName, encryptionCipher: cipher);
        await encryptedBox.close();
        if (kDebugMode) {
          debugPrint(
            'StorageMigrationService: "$boxName" already encrypted',
          );
        }
        return StorageMigrationResult.success();
      } catch (encryptedError) {
        return StorageMigrationResult.failure(
          message:
              'Your existing local data could not be upgraded to encrypted '
              'storage. Your renewals, family members, and settings may '
              'still be on this device, but the app cannot read them safely.',
          error: encryptedError,
        );
      }
    }
  }
}
