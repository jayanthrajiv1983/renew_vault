import 'extracted_document_fields.dart';

/// Template-based field extractor for a specific document type.
abstract interface class DocumentExtractor {
  String get name;

  ExtractedDocumentFields extract(String ocrText);
}
