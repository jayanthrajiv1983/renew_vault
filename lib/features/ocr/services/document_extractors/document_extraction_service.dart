import '../../../../core/services/logging_service.dart';
import '../../../../services/ocr/ocr_extraction_result.dart';
import '../document_classifier_service.dart';
import 'document_extractor_registry.dart';
import 'extracted_document_fields.dart';

/// Runs template extractors after classification with generic OCR fallback.
abstract final class DocumentExtractionService {
  DocumentExtractionService._();

  static const _confidenceThreshold = 50.0;
  static const _minTemplateFieldCount = 1;

  /// Applies template extraction when classification is confident, otherwise
  /// returns [genericFields]. Template results take priority; generic fills gaps.
  static List<OcrExtractionResult> extractWithFallback({
    required String ocrText,
    required DocumentClassificationResult? classification,
    required List<OcrExtractionResult> genericFields,
    bool logDecisions = true,
  }) {
    if (classification == null ||
        classification.type == DocumentType.unknown ||
        classification.confidence < _confidenceThreshold) {
      if (logDecisions) {
        LoggingService.instance.logInfo(
          'OCR',
          'Using generic extraction (classification unknown or low confidence)',
        );
      }
      return genericFields;
    }

    final extractor = DocumentExtractorRegistry.forType(classification.type);
    if (extractor == null) {
      if (logDecisions) {
        LoggingService.instance.logInfo(
          'OCR',
          'No template extractor for ${classification.displayType}, using generic',
        );
      }
      return genericFields;
    }

    final extracted = extractor.extract(ocrText);
    if (!extracted.isSufficient ||
        extracted.extractedFieldCount < _minTemplateFieldCount) {
      if (logDecisions) {
        LoggingService.instance.logInfo(
          'OCR',
          'Template extraction insufficient for ${extractor.name}, merging with generic',
        );
      }
      return _mergeTemplateWithGeneric(
        template: extracted,
        generic: genericFields,
      );
    }

    if (logDecisions) {
      LoggingService.instance.logInfo(
        'OCR',
        'Extracted fields using ${extractor.name}',
      );
    }
    return _mergeTemplateWithGeneric(
      template: extracted,
      generic: genericFields,
    );
  }

  static List<OcrExtractionResult> _mergeTemplateWithGeneric({
    required ExtractedDocumentFields template,
    required List<OcrExtractionResult> generic,
  }) {
    final templateResults = template.toOcrResults();
    final bestByField = <String, OcrExtractionResult>{};

    for (final field in generic) {
      bestByField[field.fieldName] = field;
    }

    for (final field in templateResults) {
      final existing = bestByField[field.fieldName];
      if (existing == null || field.confidence >= existing.confidence) {
        bestByField[field.fieldName] = field;
      }
    }

    return bestByField.values.toList();
  }
}
