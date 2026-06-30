import '../../features/ocr/services/document_classifier_service.dart'
    show DocumentClassificationResult;
import 'ocr_engine.dart';import 'ocr_extraction_result.dart';

/// Input for template field extraction in a background isolate.
class OcrExtractStageInput {
  const OcrExtractStageInput({
    required this.ocrText,
    required this.classification,
    required this.genericFields,
  });

  final String ocrText;
  final DocumentClassificationResult classification;
  final List<OcrExtractionResult> genericFields;
}

/// Top-level entry points for [compute] — must remain top-level functions.

OcrGenericParseResult ocrIsolateParseGeneric(String text) {
  return OcrEngine.parseGenericFromText(text);
}

DocumentClassificationResult ocrIsolateClassify(String normalizedText) {
  return OcrEngine.classifyFromText(normalizedText);
}

List<OcrExtractionResult> ocrIsolateExtractFields(OcrExtractStageInput input) {
  return OcrEngine.extractFieldsFromText(
    text: input.ocrText,
    classification: input.classification,
    genericFields: input.genericFields,
    logDecisions: false,
  );
}
