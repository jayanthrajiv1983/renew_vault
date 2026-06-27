import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../constants/attachment_limits.dart';
import '../models/attachment_metadata.dart';
import '../models/renewal_item.dart';

class AttachmentLimitReachedException implements Exception {
  AttachmentLimitReachedException(this.maxAttachments);

  final int maxAttachments;

  @override
  String toString() =>
      'Attachment limit reached ($maxAttachments per renewal).';
}

class AttachmentSaveResult {
  const AttachmentSaveResult({
    required this.item,
    required this.metadata,
  });

  final RenewalItem item;
  final AttachmentMetadata metadata;
}

class AttachmentService {
  AttachmentService._();

  static final AttachmentService instance = AttachmentService._();

  static const _attachmentsDirName = 'attachments';
  static const _uuid = Uuid();
  final ImagePicker _imagePicker = ImagePicker();

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

  Future<File> resolveAttachmentFile(AttachmentMetadata attachment) async {
    final appDir = await getApplicationDocumentsDirectory();
    return File(p.join(appDir.path, attachment.localPath));
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
    final file = await resolveAttachmentFile(attachment);
    if (await file.exists()) {
      await file.delete();
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
