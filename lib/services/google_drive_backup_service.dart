import 'dart:async';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;

import '../core/services/crashlytics_service.dart';
import '../core/services/logging_service.dart';
import '../models/backup_history_entry.dart';
import 'backup_history_service.dart';
import 'backup_service.dart';
import 'settings_service.dart';

typedef CloudUploadProgressCallback = void Function(
  double progress,
  String label,
);

class GoogleDriveBackupException implements Exception {
  GoogleDriveBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleDriveBackupFile {
  const GoogleDriveBackupFile({
    required this.id,
    required this.name,
    required this.modifiedTime,
    required this.sizeBytes,
  });

  final String id;
  final String name;
  final DateTime modifiedTime;
  final int sizeBytes;
}

class GoogleDriveBackupService {
  GoogleDriveBackupService._();

  static final GoogleDriveBackupService instance = GoogleDriveBackupService._();

  static const _folderName = 'RenewVault Backups';
  static const _driveScopes = [drive.DriveApi.driveFileScope];

  GoogleSignIn get _signIn => GoogleSignIn.instance;

  GoogleSignInAccount? _currentAccount;
  bool _initialized = false;

  GoogleSignInAccount? get currentAccount => _currentAccount;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    await _signIn.initialize();
    _signIn.authenticationEvents.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          _currentAccount = event.user;
        case GoogleSignInAuthenticationEventSignOut():
          _currentAccount = null;
      }
    });
    _initialized = true;

    final restoreFuture = _signIn.attemptLightweightAuthentication();
    if (restoreFuture != null) {
      final restored = await restoreFuture;
      if (restored != null) {
        _currentAccount = restored;
      }
    }
  }

  Future<GoogleSignInAccount> signIn() async {
    await init();
    try {
      final account = await _signIn.authenticate(scopeHint: _driveScopes);
      _currentAccount = account;
      return account;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleDriveBackupException('Sign-in was cancelled.');
      }
      throw GoogleDriveBackupException('Google sign-in failed.');
    }
  }

  Future<void> signOut() async {
    await init();
    await _signIn.signOut();
    _currentAccount = null;
  }

  Future<GoogleSignInAccount> _ensureSignedIn() async {
    await init();
    final account = _currentAccount;
    if (account != null) {
      return account;
    }

    final restoreFuture = _signIn.attemptLightweightAuthentication();
    if (restoreFuture != null) {
      final restored = await restoreFuture;
      if (restored != null) {
        _currentAccount = restored;
        return restored;
      }
    }

    return signIn();
  }

  Future<drive.DriveApi> _createDriveApi(GoogleSignInAccount account) async {
    final authz =
        await account.authorizationClient.authorizeScopes(_driveScopes);
    final client = authz.authClient(scopes: _driveScopes);
    return drive.DriveApi(client);
  }

  Future<void> uploadEncryptedBackup({
    CloudUploadProgressCallback? onProgress,
  }) async {
    await init();

    try {
      final account = await _ensureSignedIn();

      onProgress?.call(0.05, 'Creating encrypted backup...');

      final backupFile = await BackupService.instance.exportEncryptedBackup(
        onProgress: (step, progress) {
          onProgress?.call(0.05 + progress * 0.5, step.label);
        },
      );

      if (!backupFile.path.endsWith('.rvbackup')) {
        throw GoogleDriveBackupException('Invalid backup file type.');
      }

      onProgress?.call(0.6, 'Connecting to Google Drive...');

      final driveApi = await _createDriveApi(account);

      onProgress?.call(0.65, 'Preparing backup folder...');
      final folderId = await _findOrCreateFolder(driveApi);

      onProgress?.call(0.75, 'Uploading to Google Drive...');
      final fileName = p.basename(backupFile.path);
      final fileSize = await backupFile.length();

      final driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId]
        ..mimeType = 'application/octet-stream';

      final uploadedFile = await driveApi.files.create(
        driveFile,
        uploadMedia: _progressMedia(
          backupFile.openRead(),
          fileSize,
          (uploadedFraction) {
            onProgress?.call(
              0.75 + uploadedFraction * 0.2,
              'Uploading to Google Drive...',
            );
          },
        ),
      );

      onProgress?.call(1.0, 'Backup successful');

      await SettingsService.instance.setLastCloudBackupAt(DateTime.now());
      await SettingsService.instance.recordSuccessfulBackup();

      await BackupHistoryService.instance.record(
        fileName: fileName,
        filePath: backupFile.path,
        fileSizeBytes: fileSize,
        destination: 'Google Drive',
        storageType: BackupStorageType.cloud,
        cloudFileId: uploadedFile.id,
      );

      LoggingService.instance.logInfo(
        'CLOUD',
        'Backup uploaded to Google Drive',
      );
    } on GoogleDriveBackupException {
      rethrow;
    } on GoogleSignInException catch (e, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureCloud,
        'Google Drive backup failed',
        exception: e,
        stackTrace: stack,
        operation: 'Cloud Upload Failed',
      );
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleDriveBackupException('Sign-in was cancelled.');
      }
      throw GoogleDriveBackupException('Google Drive backup failed.');
    } on Exception catch (e, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureCloud,
        'Google Drive backup failed',
        exception: e,
        stackTrace: stack,
        operation: 'Cloud Upload Failed',
      );
      throw GoogleDriveBackupException('Google Drive backup failed.');
    }
  }

  drive.Media _progressMedia(
    Stream<List<int>> stream,
    int totalBytes,
    void Function(double fraction) onProgress,
  ) {
    var sent = 0;
    final progressStream = stream.map((chunk) {
      sent += chunk.length;
      if (totalBytes > 0) {
        onProgress(sent / totalBytes);
      }
      return chunk;
    });
    return drive.Media(progressStream, totalBytes);
  }

  Future<List<GoogleDriveBackupFile>> listEncryptedBackups() async {
    await init();

    try {
      final account = await _ensureSignedIn();
      final driveApi = await _createDriveApi(account);
      final folderId = await _findBackupFolderId(driveApi);
      if (folderId == null) {
        LoggingService.instance.logInfo(
          'CLOUD',
          'No Google Drive backup folder found',
        );
        return const [];
      }

      final query =
          "'$folderId' in parents and trashed = false and name contains '.rvbackup'";
      final result = await driveApi.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name, modifiedTime, size)',
        orderBy: 'modifiedTime desc',
      );

      final files = result.files ?? const [];
      final backups = files
          .where((file) => file.id != null && file.name != null)
          .map(
            (file) => GoogleDriveBackupFile(
              id: file.id!,
              name: file.name!,
              modifiedTime: file.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0),
              sizeBytes: int.tryParse(file.size ?? '') ?? 0,
            ),
          )
          .toList();

      LoggingService.instance.logInfo(
        'CLOUD',
        'Listed ${backups.length} Google Drive backups',
      );
      return backups;
    } on GoogleDriveBackupException {
      rethrow;
    } on GoogleSignInException catch (e, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureCloud,
        'Google Drive list backups failed',
        exception: e,
        stackTrace: stack,
        operation: 'Cloud List Failed',
      );
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleDriveBackupException('Sign-in was cancelled.');
      }
      throw GoogleDriveBackupException('Unable to list Google Drive backups.');
    } on Exception catch (e, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureCloud,
        'Google Drive list backups failed',
        exception: e,
        stackTrace: stack,
        operation: 'Cloud List Failed',
      );
      throw GoogleDriveBackupException('Unable to list Google Drive backups.');
    }
  }

  Future<List<int>> downloadEncryptedBackup({
    required String fileId,
    CloudUploadProgressCallback? onProgress,
  }) async {
    await init();

    try {
      final account = await _ensureSignedIn();
      onProgress?.call(0.05, 'Connecting to Google Drive...');

      final driveApi = await _createDriveApi(account);
      onProgress?.call(0.1, 'Downloading backup...');

      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final totalBytes = media.length ?? 0;
      final bytes = <int>[];
      var received = 0;

      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (totalBytes > 0) {
          onProgress?.call(
            0.1 + (received / totalBytes) * 0.85,
            'Downloading backup...',
          );
        }
      }

      if (bytes.isEmpty) {
        throw GoogleDriveBackupException('Downloaded backup file is empty.');
      }

      onProgress?.call(1.0, 'Download complete');

      LoggingService.instance.logInfo(
        'CLOUD',
        'Backup downloaded from Google Drive',
      );
      return bytes;
    } on GoogleDriveBackupException {
      rethrow;
    } on GoogleSignInException catch (e, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureCloud,
        'Google Drive download failed',
        exception: e,
        stackTrace: stack,
        operation: 'Cloud Download Failed',
      );
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleDriveBackupException('Sign-in was cancelled.');
      }
      throw GoogleDriveBackupException('Google Drive download failed.');
    } on Exception catch (e, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureCloud,
        'Google Drive download failed',
        exception: e,
        stackTrace: stack,
        operation: 'Cloud Download Failed',
      );
      throw GoogleDriveBackupException('Google Drive download failed.');
    }
  }

  Future<String?> _findBackupFolderId(drive.DriveApi driveApi) async {
    final escapedName = _folderName.replaceAll("'", "\\'");
    final query =
        "name = '$escapedName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";

    final result = await driveApi.files.list(
      q: query,
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    final files = result.files;
    if (files != null && files.isNotEmpty) {
      return files.first.id;
    }
    return null;
  }

  Future<String> _findOrCreateFolder(drive.DriveApi driveApi) async {
    final existingId = await _findBackupFolderId(driveApi);
    if (existingId != null) {
      return existingId;
    }

    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final created = await driveApi.files.create(folder);
    if (created.id == null) {
      throw GoogleDriveBackupException('Unable to create backup folder.');
    }
    return created.id!;
  }
}
