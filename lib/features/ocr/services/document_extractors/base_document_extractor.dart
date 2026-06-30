import '../../../../services/ocr/document_parser.dart';
import '../../../../services/ocr/document_type.dart' as legacy;
import '../../../../services/ocr/ocr_extraction_result.dart';
import 'document_extractor.dart';
import 'extracted_document_fields.dart';

/// Shared parsing utilities from [DocumentParser] for template extractors.
abstract class BaseDocumentExtractor extends DocumentParser
    implements DocumentExtractor {
  @override
  legacy.DocumentType get documentType => legacy.DocumentType.unknown;

  @override
  List<OcrExtractionResult> parse(String text) => extract(text).toOcrResults();

  ExtractedDocumentFields buildFields({
    required List<OcrExtractionResult> results,
    String? title,
    String? provider,
    String? brand,
    String? model,
    String? amount,
    String? vendor,
    String? purchaseDate,
    String? invoiceDate,
    int confidence = 85,
  }) {
    String? docNum;
    String? issue;
    String? expiry;
    String? authority;
    final extra = <String, String>{};
    final fieldConfidences = <String, int>{};

    for (final result in results) {
      fieldConfidences[result.fieldName] = result.confidence;
      switch (result.fieldName) {
        case 'documentNumber':
          docNum ??= result.extractedValue;
        case 'issueDate':
          issue ??= result.extractedValue;
        case 'expiryDate':
          expiry ??= result.extractedValue;
        case 'authority':
          authority ??= result.extractedValue;
        case 'amount':
          amount ??= result.extractedValue;
        default:
          extra[result.fieldName] = result.extractedValue;
      }
    }

    void assignInferred(String fieldName, String? value, {required int inferred}) {
      if (value == null || value.trim().isEmpty) return;
      fieldConfidences.putIfAbsent(fieldName, () => inferred);
    }

    assignInferred('provider', provider, inferred: 70);
    assignInferred('brand', brand, inferred: 65);
    assignInferred('model', model, inferred: 65);
    assignInferred('amount', amount, inferred: 68);
    assignInferred('vendor', vendor, inferred: 70);
    assignInferred('purchaseDate', purchaseDate, inferred: 75);
    assignInferred('invoiceDate', invoiceDate, inferred: 75);

    final avgConfidence = fieldConfidences.isEmpty
        ? confidence
        : (fieldConfidences.values.reduce((a, b) => a + b) /
                fieldConfidences.length)
            .round()
            .clamp(0, 100);

    return ExtractedDocumentFields(
      title: title,
      documentNumber: docNum,
      issueDate: issue,
      expiryDate: expiry,
      authority: authority,
      provider: provider,
      brand: brand,
      model: model,
      amount: amount,
      vendor: vendor,
      purchaseDate: purchaseDate,
      invoiceDate: invoiceDate,
      fields: extra,
      fieldConfidences: fieldConfidences,
      confidence: avgConfidence,
    );
  }
}
