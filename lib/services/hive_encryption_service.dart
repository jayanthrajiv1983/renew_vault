import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Manages the Hive AES-256 encryption key in platform secure storage.
class HiveEncryptionService {
  HiveEncryptionService._();

  static final HiveEncryptionService instance = HiveEncryptionService._();

  static const encryptionKeyName = 'hive_encryption_key';
  static const migrationFlagKey = 'encryption_migrated_v1';
  static const encryptionKeyByteLength = 32;

  static const encryptedBoxNames = <String>[
    'renewals',
    'family_members',
    'settings',
    'ocr_corrections',
  ];

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  HiveAesCipher? _cipher;

  Future<HiveAesCipher> getCipher() async {
    _cipher ??= HiveAesCipher(await getOrCreateEncryptionKey());
    return _cipher!;
  }

  Future<List<int>> getOrCreateEncryptionKey() async {
    final existing = await _secureStorage.read(key: encryptionKeyName);
    if (existing != null && existing.isNotEmpty) {
      final decoded = base64Decode(existing);
      if (decoded.length == encryptionKeyByteLength) {
        return decoded;
      }
    }

    final key = List<int>.generate(
      encryptionKeyByteLength,
      (_) => Random.secure().nextInt(256),
    );
    await _secureStorage.write(
      key: encryptionKeyName,
      value: base64Encode(key),
    );
    return key;
  }

  Future<bool> isMigrationComplete() async {
    return await _secureStorage.read(key: migrationFlagKey) == 'true';
  }

  Future<void> markMigrationComplete() async {
    await _secureStorage.write(key: migrationFlagKey, value: 'true');
  }

  Future<Box<T>> openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }

    final cipher = await getCipher();
    return Hive.openBox<T>(name, encryptionCipher: cipher);
  }
}
