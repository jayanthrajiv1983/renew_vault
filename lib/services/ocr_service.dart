import 'dart:io';

import 'image_preprocessor.dart';
import 'ocr/ocr_engine.dart';
import 'ocr/ocr_extraction_result.dart';
import 'ocr/ocr_scan_pipeline.dart';

export 'ocr/document_type.dart';
export 'ocr/ocr_engine.dart';
export 'ocr/ocr_extraction_result.dart';
export 'ocr/ocr_performance_metrics.dart';
export 'ocr/ocr_scan_pipeline.dart';
export 'ocr/ocr_scan_stage.dart';

/// Legacy wrapper around [OcrEngine] for backward compatibility.
class OcrService {
  OcrService._();

  static Future<String> scanImage(String path) async {
    final result = await OcrEngine.processImage(path);
    return result.rawText;
  }

  static Future<OcrEngineResult> scanAndParse(String path) {
    return OcrEngine.scanAndParse(path);
  }

  /// Fast scan: one ML Kit pass, one parser pass, no learned corrections.
  static Future<OcrEngineResult> fastScanAndParse(String path) {
    return OcrEngine.fastScanAndParse(path);
  }

  /// Staged scan with background isolates and progress reporting.
  static Future<OcrScanPipelineResult> scanWithProgress(
    String path, {
    OcrProgressCallback? onProgress,
  }) {
    return OcrScanPipeline.scan(path, onProgress: onProgress);
  }

  /// Alias for [fastScanAndParse].
  static Future<OcrEngineResult> fastScan(String path) {
    return fastScanAndParse(path);
  }

  /// Preprocesses [input], runs OCR on the enhanced image, then deletes the temp file.
  static Future<OcrEngineResult> scanAndParseWithPreprocessing(File input) async {
    final processed = await ImagePreprocessor.process(input);
    try {
      return await OcrEngine.scanAndParse(processed.path);
    } finally {
      if (await processed.exists()) {
        await processed.delete();
      }
    }
  }

  static OcrEngineResult parseDocumentFields(String text) {
    return OcrEngine.processText(text);
  }

  static void dispose() {
    OcrEngine.dispose();
  }
}

/// @deprecated Use [OcrExtractionResult] and [OcrEngineResult] instead.
class ParsedDocumentFields {
  const ParsedDocumentFields({
    this.documentNumber,
    this.issueDate,
    this.expiryDate,
    this.authority,
  });

  final String? documentNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? authority;

  bool get hasAny =>
      documentNumber != null ||
      issueDate != null ||
      expiryDate != null ||
      authority != null;

  factory ParsedDocumentFields.fromEngineResult(OcrEngineResult result) {
    DateTime? parseDate(String value) {
      final parts = value.split('/');
      if (parts.length != 3) {
        return null;
      }
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day == null || month == null || year == null) {
        return null;
      }
      try {
        return DateTime(year, month, day);
      } on ArgumentError {
        return null;
      }
    }

    String? docNum;
    DateTime? issue;
    DateTime? expiry;
    String? auth;

    for (final field in result.highConfidenceFields) {
      switch (field.fieldName) {
        case 'documentNumber':
          docNum = field.extractedValue;
        case 'issueDate':
          issue = parseDate(field.extractedValue);
        case 'expiryDate':
          expiry = parseDate(field.extractedValue);
        case 'authority':
          auth = field.extractedValue;
      }
    }

    return ParsedDocumentFields(
      documentNumber: docNum,
      issueDate: issue,
      expiryDate: expiry,
      authority: auth,
    );
  }
}
