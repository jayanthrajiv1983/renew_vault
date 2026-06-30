import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'hive_encryption_service.dart';

/// Encrypts attachment files at rest using AES-256-CBC (same key as Hive).
class AttachmentEncryptionService {
  AttachmentEncryptionService._();

  static final AttachmentEncryptionService instance =
      AttachmentEncryptionService._();

  static const _magicBytes = [0x52, 0x56, 0x45, 0x41]; // "RVEA"
  static const formatVersion = 1;
  static const migrationFlagKey = 'attachment_encryption_migrated_v1';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final Map<String, File> _decryptedCache = {};

  bool isEncryptedBytes(List<int> bytes) {
    if (bytes.length < _magicBytes.length + 1 + 16) {
      return false;
    }
    for (var i = 0; i < _magicBytes.length; i++) {
      if (bytes[i] != _magicBytes[i]) {
        return false;
      }
    }
    return bytes[_magicBytes.length] == formatVersion;
  }

  Future<bool> isEncryptedFile(File file) async {
    if (!await file.exists()) {
      return false;
    }
    final length = await file.length();
    if (length < _magicBytes.length + 1 + 16) {
      return false;
    }
    final header = await file.openRead(0, _magicBytes.length + 1).first;
    return isEncryptedBytes(header);
  }

  Future<List<int>> encryptBytes(List<int> plainBytes) async {
    final keyBytes =
        await HiveEncryptionService.instance.getOrCreateEncryptionKey();
    final key = Key(Uint8List.fromList(keyBytes));
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    final output = BytesBuilder(copy: false);
    output.add(_magicBytes);
    output.addByte(formatVersion);
    output.add(iv.bytes);
    output.add(encrypted.bytes);
    return output.toBytes();
  }

  Future<List<int>> decryptBytes(List<int> encryptedBytes) async {
    if (!isEncryptedBytes(encryptedBytes)) {
      return encryptedBytes;
    }

    final ivOffset = _magicBytes.length + 1;
    const ivLength = 16;
    final iv = IV(
      Uint8List.fromList(
        encryptedBytes.sublist(ivOffset, ivOffset + ivLength),
      ),
    );
    final ciphertext = encryptedBytes.sublist(ivOffset + ivLength);

    final keyBytes =
        await HiveEncryptionService.instance.getOrCreateEncryptionKey();
    final key = Key(Uint8List.fromList(keyBytes));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.decryptBytes(
      Encrypted(Uint8List.fromList(ciphertext)),
      iv: iv,
    );
  }

  Future<void> encryptFileInPlace(File file) async {
    if (await isEncryptedFile(file)) {
      return;
    }
    final plainBytes = await file.readAsBytes();
    final encryptedBytes = await encryptBytes(plainBytes);
    await file.writeAsBytes(encryptedBytes, flush: true);
  }

  /// Returns a decrypted temp file suitable for display or external open.
  Future<File> decryptToReadableFile({
    required File storedFile,
    required String cacheKey,
  }) async {
    if (!await storedFile.exists()) {
      return storedFile;
    }

    if (!await isEncryptedFile(storedFile)) {
      return storedFile;
    }

    final cached = _decryptedCache[cacheKey];
    if (cached != null && await cached.exists()) {
      return cached;
    }

    final encryptedBytes = await storedFile.readAsBytes();
    final plainBytes = await decryptBytes(encryptedBytes);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      p.join(tempDir.path, 'rv_attachment_$cacheKey'),
    );
    await tempFile.writeAsBytes(plainBytes, flush: true);
    _decryptedCache[cacheKey] = tempFile;
    return tempFile;
  }

  Future<bool> isMigrationComplete() async {
    return await _secureStorage.read(key: migrationFlagKey) == 'true';
  }

  Future<void> markMigrationComplete() async {
    await _secureStorage.write(key: migrationFlagKey, value: 'true');
  }

  /// Encrypts legacy plain-text attachment files on disk.
  Future<void> migratePlainAttachmentsIfNeeded() async {
    if (await isMigrationComplete()) {
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsRoot = Directory(p.join(appDir.path, 'attachments'));
    if (await attachmentsRoot.exists()) {
      await for (final entity in attachmentsRoot.list(recursive: true)) {
        if (entity is! File) {
          continue;
        }
        await encryptFileInPlace(entity);
      }
    }

    await markMigrationComplete();
  }

  void clearDecryptedCache() {
    for (final file in _decryptedCache.values) {
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    _decryptedCache.clear();
  }
}
