import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../models/add_item_prefill.dart';
import '../models/attachment_metadata.dart';
import '../screens/add_item_screen.dart';
import '../screens/ocr_review_screen.dart';
import '../core/services/logging_service.dart';
import '../widgets/ocr/ocr_scan_helpers.dart';
import 'ocr/ocr_form_mapper.dart';
import 'ocr_service.dart';
import 'ocr_correction_service.dart';

/// Orchestrates document scan/upload → OCR → review for new renewal creation.
abstract final class RenewalCreationFlow {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Camera/gallery → OCR → review. Returns null if cancelled.
  static Future<AddItemPrefill?> runScanDocumentFlow(
    BuildContext context, {
    bool hasExistingData = false,
    String currentCategory = 'Appliance',
  }) async {
    final source = await showOcrSourcePicker(context);
    if (source == null || !context.mounted) {
      return null;
    }

    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image == null || !context.mounted) {
      return null;
    }

    return _runOcrReviewForImage(
      context,
      imagePath: image.path,
      hasExistingData: hasExistingData,
      currentCategory: currentCategory,
      launchMode: AddItemLaunchMode.scanDocument,
      onRetake: () => runScanDocumentFlow(
        context,
        hasExistingData: hasExistingData,
        currentCategory: currentCategory,
      ),
    );
  }

  /// File picker (image/PDF) → OCR when supported → review when applicable.
  static Future<AddItemPrefill?> runUploadDocumentFlow(
    BuildContext context, {
    bool hasExistingData = false,
    String currentCategory = 'Appliance',
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty || !context.mounted) {
      return null;
    }

    final picked = result.files.single;
    final path = picked.path;
    if (path == null) {
      return null;
    }

    final fileType =
        AttachmentFileType.fromExtension(p.extension(path)) ??
            AttachmentFileType.jpg;

    if (fileType == AttachmentFileType.pdf) {
      return AddItemPrefill(
        attachmentPath: path,
        fileType: fileType,
        launchMode: AddItemLaunchMode.uploadDocument,
        infoMessage: 'PDF attached. Fill in the details manually.',
      );
    }

    return _runOcrReviewForImage(
      context,
      imagePath: path,
      hasExistingData: hasExistingData,
      currentCategory: currentCategory,
      launchMode: AddItemLaunchMode.uploadDocument,
      onRetake: () => runUploadDocumentFlow(
        context,
        hasExistingData: hasExistingData,
        currentCategory: currentCategory,
      ),
    );
  }

  static Future<AddItemPrefill?> _runOcrReviewForImage(
    BuildContext context, {
    required String imagePath,
    required bool hasExistingData,
    required String currentCategory,
    required AddItemLaunchMode launchMode,
    required Future<AddItemPrefill?> Function() onRetake,
  }) async {
    var overlayShown = false;
    try {
      LoggingService.instance.logInfo('OCR', 'Scan started');

      if (context.mounted) {
        overlayShown = true;
        showOcrScanningOverlay(context);
      }

      final result = await OcrService.fastScanAndParse(imagePath);
      LoggingService.instance.logInfo('OCR', 'Scan completed');
      final correctedFields =
          OcrCorrectionService.instance.applyLearnedCorrections(
        result.fields,
        documentType: result.documentType.name,
      );
      final enhancedResult = OcrEngineResult(
        rawText: result.rawText,
        documentType: result.documentType,
        fields: correctedFields,
      );

      if (overlayShown && context.mounted) {
        dismissOcrScanningOverlay(context);
        overlayShown = false;
      }

      if (!context.mounted) {
        return null;
      }

      final rawOcrValues = OcrFormMapper.rawValuesFrom(result);
      final initialData = OcrFormMapper.initialReviewData(
        enhancedResult,
        rawOcrValues: rawOcrValues,
        allowedCategories: AddItemScreen.categories,
        currentCategory: currentCategory,
      );

      final fileType =
          AttachmentFileType.fromExtension(p.extension(imagePath)) ??
              AttachmentFileType.jpg;

      final reviewResult = await Navigator.of(context).push<Object?>(
        MaterialPageRoute(
          builder: (context) => OcrReviewScreen(
            imagePath: imagePath,
            result: enhancedResult,
            initialData: initialData,
            categories: AddItemScreen.categories,
            hasExistingData: hasExistingData,
          ),
        ),
      );

      if (!context.mounted) {
        return null;
      }

      if (reviewResult == OcrReviewOutcome.retake) {
        return onRetake();
      }

      if (reviewResult is! OcrReviewData) {
        return null;
      }

      return AddItemPrefill(
        reviewData: reviewResult,
        attachmentPath: imagePath,
        fileType: fileType,
        launchMode: launchMode,
      );
    } catch (e) {
      LoggingService.instance.logError('OCR', 'Scan failed');
      if (overlayShown && context.mounted) {
        dismissOcrScanningOverlay(context);
        overlayShown = false;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
      return null;
    } finally {
      if (overlayShown && context.mounted) {
        dismissOcrScanningOverlay(context);
      }
    }
  }
}
