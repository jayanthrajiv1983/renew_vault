import '../services/ocr/ocr_form_mapper.dart';
import 'attachment_metadata.dart';

/// How the add-renewal form was opened from the primary creation flow.
enum AddItemLaunchMode {
  manual,
  scanDocument,
  uploadDocument,
}

/// Pre-filled data from scan/upload OCR flow before opening [AddItemScreen].
class AddItemPrefill {
  const AddItemPrefill({
    this.reviewData,
    required this.attachmentPath,
    required this.fileType,
    this.infoMessage,
    this.launchMode = AddItemLaunchMode.manual,
  });

  final OcrReviewData? reviewData;
  final String attachmentPath;
  final AttachmentFileType fileType;
  final String? infoMessage;
  final AddItemLaunchMode launchMode;
}
