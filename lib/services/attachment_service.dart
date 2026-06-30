import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../constants/attachment_limits.dart';
import '../core/services/logging_service.dart';
import '../models/attachment_metadata.dart';
import '../models/renewal_item.dart';
import 'attachment_encryption_service.dart';

class AttachmentLimitReachedException implements Exception {
  AttachmentLimitReachedException(this.maxAttachments);

  final int maxAttachments;

  @override
  String toString() =>
      'Attachment limit reached ($maxAttachments per item).';
}

class AttachmentSaveResult {
  const AttachmentSaveResult({
    required this.item,
    required this.metadata,
  });

  final RenewalItem item;
  final AttachmentMetadata metadata;
}

/// Decrypted attachment payload plus diagnostics for in-app viewing.
class AttachmentViewData {
  const AttachmentViewData({
    required this.imageBytes,
    required this.storedExists,
    required this.isEncrypted,
    required this.decryptionAttempted,
    required this.decryptionSucceeded,
    required this.missingOrCorrupt,
  });

  final Uint8List imageBytes;
  final bool storedExists;
  final bool isEncrypted;
  final bool decryptionAttempted;
  final bool decryptionSucceeded;
  final bool missingOrCorrupt;
}

class AttachmentService {
  AttachmentService._();

  static final AttachmentService instance = AttachmentService._();

  static const _attachmentsDirName = 'attachments';
  static const _ocrStagingDirName = 'ocr_staging';
  static const _uuid = Uuid();
  final ImagePicker _imagePicker = ImagePicker();

  /// Copies an OCR capture to permanent app storage before OCR/review delays.
  Future<File> persistOcrCaptureSource(File sourceFile) async {
    if (!await sourceFile.exists()) {
      throw FileSystemException('OCR source file missing', sourceFile.path);
    }

    final fileType =
        _fileTypeFromPath(sourceFile.path) ?? AttachmentFileType.jpg;
    final appDir = await getApplicationDocumentsDirectory();
    final stagingDir = Directory(p.join(appDir.path, _ocrStagingDirName));
    await stagingDir.create(recursive: true);

    final stagedFile = File(
      p.join(stagingDir.path, '${_uuid.v4()}.${fileType.extension}'),
    );
    await sourceFile.copy(stagedFile.path);

    logAttachmentSaveDiagnostics(
      attachmentId: 'ocr-staging',
      relativePath: p.join(_ocrStagingDirName, p.basename(stagedFile.path)),
      fileType: fileType,
      storedFile: stagedFile,
      encrypted: false,
      source: 'ocr_capture',
    );

    return stagedFile;
  }

  /// Removes a staged OCR file after it has been copied into attachment storage.
  Future<void> cleanupOcrStagingFile(String filePath) async {
    if (!isOcrStagingPath(filePath)) {
      return;
    }

    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      LoggingService.instance.logInfo(
        'OCR',
        'Staging file removed attachmentId=ocr-staging ext=${p.extension(filePath).replaceAll('.', '')}',
      );
    }
  }

  bool isOcrStagingPath(String filePath) {
    final normalized = filePath.replaceAll('\\', '/');
    return normalized.contains('/$_ocrStagingDirName/');
  }

  bool canAddAttachment(RenewalItem item, {bool isPremium = false}) {
    return canAddAttachmentCount(
      item.attachments.length,
      isPremium: isPremium,
    );
  }

  bool canAddAttachmentCount(int currentCount, {bool isPremium = false}) {
    return currentCount <
        AttachmentLimits.maxAttachmentsForItem(isPremium: isPremium);
  }

  /// True when the item is at the attachment cap but has files to replace.
  bool shouldOfferReplace(int attachmentCount, {bool isPremium = false}) {
    return attachmentCount > 0 &&
        !canAddAttachmentCount(attachmentCount, isPremium: isPremium);
  }

  bool shouldOfferReplaceForItem(RenewalItem item, {bool isPremium = false}) {
    return shouldOfferReplace(item.attachments.length, isPremium: isPremium);
  }

  /// Picks a new attachment on a cleared item, then deletes [replaceTarget] from disk.
  Future<AttachmentSaveResult?> pickThenReplace({
    required RenewalItem item,
    required AttachmentMetadata replaceTarget,
    required Future<AttachmentSaveResult?> Function(
      RenewalItem item, {
      bool isPremium,
    }) picker,
    bool isPremium = false,
  }) async {
    final cleared = item.copyWith(
      attachments: item.attachments
          .where((entry) => entry.id != replaceTarget.id)
          .toList(),
    );
    final result = await picker(cleared, isPremium: isPremium);
    if (result == null) {
      return null;
    }
    await deleteAttachmentFileOnly(replaceTarget);
    return result;
  }

  RenewalItem stubItemForAttachments({
    required String renewalItemId,
    List<AttachmentMetadata> attachments = const [],
  }) {
    return RenewalItem(
      id: renewalItemId,
      title: '',
      category: '',
      owner: '',
      renewalDate: DateTime.now(),
      attachments: attachments,
    );
  }

  Future<Directory> getAttachmentsRootDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(
      p.join(appDir.path, _attachmentsDirName),
    );
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir;
  }

  Future<File> resolveStoredAttachmentFile(AttachmentMetadata attachment) async {
    final appDir = await getApplicationDocumentsDirectory();
    return File(p.join(appDir.path, attachment.localPath));
  }

  /// Returns a decrypted readable file for display, open, or copy operations.
  Future<File> resolveAttachmentFile(AttachmentMetadata attachment) async {
    final viewData = await resolveAttachmentForView(attachment);
    if (viewData.missingOrCorrupt) {
      return resolveStoredAttachmentFile(attachment);
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      p.join(
        tempDir.path,
        'rv_attachment_${attachment.id}.${attachment.fileType.extension}',
      ),
    );
    await tempFile.writeAsBytes(viewData.imageBytes, flush: true);
    return tempFile;
  }

  /// Resolves attachment bytes for in-app image viewing with full diagnostics.
  Future<AttachmentViewData> resolveAttachmentForView(
    AttachmentMetadata attachment,
  ) async {
    final storedFile = await resolveStoredAttachmentFile(attachment);
    final storedExists = await storedFile.exists();
    final storedSizeBytes = storedExists ? await storedFile.length() : 0;
    final encrypted = storedExists &&
        await AttachmentEncryptionService.instance.isEncryptedFile(storedFile);

    var decryptionAttempted = false;
    var decryptionSucceeded = false;
    Uint8List imageBytes = Uint8List(0);

    if (!storedExists) {
      logAttachmentViewDiagnostics(
        attachment: attachment,
        storedFile: storedFile,
        storedExists: storedExists,
        storedSizeBytes: storedSizeBytes,
        isEncrypted: encrypted,
        decryptionAttempted: false,
        decryptionSucceeded: false,
        imageBytesLength: 0,
      );
      return AttachmentViewData(
        imageBytes: imageBytes,
        storedExists: false,
        isEncrypted: false,
        decryptionAttempted: false,
        decryptionSucceeded: false,
        missingOrCorrupt: true,
      );
    }

    try {
      if (encrypted) {
        decryptionAttempted = true;
        final encryptedBytes = await storedFile.readAsBytes();
        final plainBytes =
            await AttachmentEncryptionService.instance.decryptBytes(
          encryptedBytes,
        );
        imageBytes = Uint8List.fromList(plainBytes);
        decryptionSucceeded = imageBytes.isNotEmpty &&
            !AttachmentEncryptionService.instance
                .hasEncryptedHeader(imageBytes);
      } else {
        imageBytes = Uint8List.fromList(await storedFile.readAsBytes());
        decryptionSucceeded = imageBytes.isNotEmpty;
      }
    } catch (error, stack) {
      LoggingService.instance.logError(
        'ATTACHMENTS',
        'Decrypt failed attachmentId=${attachment.id}',
        exception: error,
        stackTrace: stack,
        operation: 'Attachment View',
      );
      decryptionAttempted = encrypted;
      decryptionSucceeded = false;
    }

    final missingOrCorrupt = !decryptionSucceeded || imageBytes.isEmpty;

    logAttachmentViewDiagnostics(
      attachment: attachment,
      storedFile: storedFile,
      storedExists: storedExists,
      storedSizeBytes: storedSizeBytes,
      isEncrypted: encrypted,
      decryptionAttempted: decryptionAttempted,
      decryptionSucceeded: decryptionSucceeded,
      imageBytesLength: imageBytes.length,
    );

    return AttachmentViewData(
      imageBytes: imageBytes,
      storedExists: storedExists,
      isEncrypted: encrypted,
      decryptionAttempted: decryptionAttempted,
      decryptionSucceeded: decryptionSucceeded,
      missingOrCorrupt: missingOrCorrupt,
    );
  }

  void logAttachmentSaveDiagnostics({
    required String attachmentId,
    required String relativePath,
    required AttachmentFileType fileType,
    required File storedFile,
    required bool encrypted,
    String source = 'save',
  }) {
    final exists = storedFile.existsSync();
    final sizeBytes = exists ? storedFile.lengthSync() : 0;
    LoggingService.instance.logInfo(
      source == 'ocr_capture' ? 'OCR' : 'ATTACHMENTS',
      'Save attachmentId=$attachmentId ext=${fileType.extension} '
      'exists=$exists sizeBytes=$sizeBytes encrypted=$encrypted source=$source '
      'relativePath=${relativePath.replaceAll('\\', '>')}',
    );
  }

  void logAttachmentViewDiagnostics({
    required AttachmentMetadata attachment,
    required File storedFile,
    required bool storedExists,
    required int storedSizeBytes,
    required bool isEncrypted,
    required bool decryptionAttempted,
    required bool decryptionSucceeded,
    required int imageBytesLength,
    String? viewerPath,
  }) {
    LoggingService.instance.logInfo(
      'ATTACHMENTS',
      'Viewer attachmentId=${attachment.id} '
      'fileName=${attachment.fileName} '
      'ext=${attachment.fileType.extension} '
      'storedExists=$storedExists '
      'storedSizeBytes=$storedSizeBytes '
      'isEncrypted=$isEncrypted '
      'decryptionAttempted=$decryptionAttempted '
      'decryptionSucceeded=$decryptionSucceeded '
      'imageBytesLength=$imageBytesLength '
      'relativePath=${attachment.localPath.replaceAll('\\', '>')} '
      'storedAbsolute=${storedFile.path.replaceAll('\\', '>')} '
      '${viewerPath != null ? 'viewerPath=${viewerPath.replaceAll('\\', '>')} ' : ''}'
      'mime=${attachment.fileType.label}',
    );
  }

  /// Raw on-disk bytes (encrypted when migration is complete).
  Future<List<int>> readStoredAttachmentBytes(
    AttachmentMetadata attachment,
  ) async {
    final file = await resolveStoredAttachmentFile(attachment);
    if (!await file.exists()) {
      return const [];
    }
    return file.readAsBytes();
  }

  String _relativePath(String renewalItemId, String attachmentId, String ext) {
    return p.join(_attachmentsDirName, renewalItemId, '$attachmentId.$ext');
  }

  Future<AttachmentSaveResult> saveFile({
    required RenewalItem item,
    required File sourceFile,
    required AttachmentFileType fileType,
    String? preferredFileName,
    bool isPremium = false,
  }) async {
    if (!canAddAttachment(item, isPremium: isPremium)) {
      throw AttachmentLimitReachedException(
        AttachmentLimits.maxAttachmentsForItem(isPremium: isPremium),
      );
    }

    final attachmentId = _uuid.v4();
    final fileName = preferredFileName ??
        p.basename(sourceFile.path).replaceAll(RegExp(r'[^\w.\- ]'), '_');
    final relativePath = _relativePath(
      item.id,
      attachmentId,
      fileType.extension,
    );
    final appDir = await getApplicationDocumentsDirectory();
    final destinationFile = File(p.join(appDir.path, relativePath));
    await destinationFile.parent.create(recursive: true);
    await sourceFile.copy(destinationFile.path);
    await AttachmentEncryptionService.instance.encryptFileInPlace(
      destinationFile,
    );

    logAttachmentSaveDiagnostics(
      attachmentId: attachmentId,
      relativePath: relativePath.replaceAll('\\', '/'),
      fileType: fileType,
      storedFile: destinationFile,
      encrypted: true,
    );

    final metadata = AttachmentMetadata(
      id: attachmentId,
      renewalItemId: item.id,
      fileName: fileName,
      fileType: fileType,
      localPath: relativePath.replaceAll('\\', '/'),
      uploadedAt: DateTime.now(),
      fileSize: await destinationFile.length(),
    );

    final updatedItem = item.copyWith(
      attachments: [...item.attachments, metadata],
    );

    return AttachmentSaveResult(item: updatedItem, metadata: metadata);
  }

  Future<AttachmentSaveResult?> pickFromScan(
    RenewalItem item, {
    bool isPremium = false,
  }) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 90,
    );
    if (picked == null) {
      return null;
    }

    return saveFile(
      item: item,
      sourceFile: File(picked.path),
      fileType: AttachmentFileType.jpg,
      preferredFileName: _defaultImageName('scan', AttachmentFileType.jpg),
      isPremium: isPremium,
    );
  }

  Future<AttachmentSaveResult?> pickFromCamera(
    RenewalItem item, {
    bool isPremium = false,
  }) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (picked == null) {
      return null;
    }

    return saveFile(
      item: item,
      sourceFile: File(picked.path),
      fileType: AttachmentFileType.jpg,
      preferredFileName: _defaultImageName('camera', AttachmentFileType.jpg),
      isPremium: isPremium,
    );
  }

  Future<AttachmentSaveResult?> pickFromGallery(
    RenewalItem item, {
    bool isPremium = false,
  }) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (picked == null) {
      return null;
    }

    final fileType =
        _fileTypeFromPath(picked.path) ?? AttachmentFileType.jpg;

    return saveFile(
      item: item,
      sourceFile: File(picked.path),
      fileType: fileType,
      preferredFileName: p.basename(picked.path),
      isPremium: isPremium,
    );
  }

  Future<AttachmentSaveResult?> pickPdf(
    RenewalItem item, {
    bool isPremium = false,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final picked = result.files.single;
    final path = picked.path;
    if (path == null) {
      return null;
    }

    return saveFile(
      item: item,
      sourceFile: File(path),
      fileType: AttachmentFileType.pdf,
      preferredFileName: picked.name,
      isPremium: isPremium,
    );
  }

  Future<void> deleteAttachmentFileOnly(AttachmentMetadata attachment) async {
    AttachmentEncryptionService.instance.evictDecryptedCache(attachment.id);
    final storedFile = await resolveStoredAttachmentFile(attachment);
    if (await storedFile.exists()) {
      await storedFile.delete();
    }
    await _cleanupEmptyRenewalDirectory(attachment.renewalItemId);
  }

  Future<void> deleteAllAttachmentFilesForList(
    List<AttachmentMetadata> attachments,
  ) async {
    for (final attachment in attachments) {
      await deleteAttachmentFileOnly(attachment);
    }
  }

  Future<RenewalItem> deleteAttachment(
    RenewalItem item,
    AttachmentMetadata attachment,
  ) async {
    await deleteAttachmentFileOnly(attachment);

    return item.copyWith(
      attachments: item.attachments
          .where((entry) => entry.id != attachment.id)
          .toList(),
    );
  }

  Future<void> deleteAllAttachmentFiles(RenewalItem item) async {
    await deleteAllAttachmentFilesForList(item.attachments);
  }

  Future<OpenResult> openAttachment(AttachmentMetadata attachment) async {
    final file = await resolveAttachmentFile(attachment);
    if (!await file.exists()) {
      return OpenResult(
        type: ResultType.fileNotFound,
        message: 'Attachment file not found.',
      );
    }
    return OpenFilex.open(file.path);
  }

  AttachmentFileType? _fileTypeFromPath(String path) {
    return AttachmentFileType.fromExtension(p.extension(path));
  }

  String _defaultImageName(String source, AttachmentFileType fileType) {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return '${source}_$timestamp.${fileType.extension}';
  }

  Future<void> _cleanupEmptyRenewalDirectory(String renewalItemId) async {
    final root = await getAttachmentsRootDirectory();
    final renewalDir = Directory(p.join(root.path, renewalItemId));
    if (!await renewalDir.exists()) {
      return;
    }

    final isEmpty = await renewalDir.list().isEmpty;
    if (isEmpty) {
      await renewalDir.delete(recursive: true);
    }
  }
}
