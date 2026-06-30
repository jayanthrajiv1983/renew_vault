import '../../../../services/ocr/document_parser.dart';
import '../../../../services/ocr/ocr_extraction_result.dart';
import 'base_document_extractor.dart';
import 'extracted_document_fields.dart';

class WarrantyExtractor extends BaseDocumentExtractor {
  static const _brandLabels = [
    'brand',
    'manufacturer',
    'make',
    'company',
  ];

  static const _modelLabels = [
    'model',
    'model no',
    'model number',
    'product',
  ];

  static const _purchaseLabels = [
    'purchase date',
    'date of purchase',
    'bought on',
    'invoice date',
  ];

  static const _expiryLabels = [
    'warranty valid',
    'warranty until',
    'valid till',
    'valid upto',
    'expiry date',
    'warranty expires',
  ];

  @override
  String get name => 'WarrantyExtractor';

  @override
  ExtractedDocumentFields extract(String ocrText) {
    final normalized = normalizeText(ocrText);
    final brand = _extractLabeledValue(normalized, _brandLabels);
    final model = _extractLabeledValue(normalized, _modelLabels);
    final purchaseDate = _extractLabeledDate(normalized, _purchaseLabels);
    final expiryDate = _extractLabeledDate(normalized, _expiryLabels) ??
        extractExpiryDate(
          normalized,
          proximityKeywords: const ['warranty', 'valid', 'guarantee'],
        );

    final serialNumber = _extractSerialNumber(normalized);

    return buildFields(
      title: 'Warranty Card',
      brand: brand,
      model: model,
      purchaseDate: purchaseDate?.extractedValue,
      results: mergeResults([
        serialNumber,
        purchaseDate,
        expiryDate,
      ]),
    );
  }

  OcrExtractionResult? _extractSerialNumber(String text) {
    const labels = ['serial no', 'serial number', 's/n', 'sr no'];
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      for (final label in labels) {
        final idx = lower.indexOf(label);
        if (idx < 0) continue;
        final value = lines[i]
            .substring(idx + label.length)
            .trim()
            .replaceFirst(RegExp(r'^[:\-\.\s]+'), '')
            .trim();
        if (value.length >= 4) {
          return OcrExtractionResult(
            fieldName: 'documentNumber',
            extractedValue: value.split(RegExp(r'\s+')).first,
            confidence: 80,
          );
        }
        if (i + 1 < lines.length) {
          final next = lines[i + 1].trim();
          if (next.length >= 4) {
            return OcrExtractionResult(
              fieldName: 'documentNumber',
              extractedValue: next.split(RegExp(r'\s+')).first,
              confidence: 76,
            );
          }
        }
      }
    }
    return null;
  }

  String? _extractLabeledValue(String text, List<String> labels) {
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      for (final label in labels) {
        final idx = lower.indexOf(label);
        if (idx < 0) continue;
        var value = lines[i]
            .substring(idx + label.length)
            .trim()
            .replaceFirst(RegExp(r'^[:\-\.\s]+'), '')
            .trim();
        if (value.isEmpty && i + 1 < lines.length) {
          value = lines[i + 1].trim();
        }
        if (value.length >= 2 && value.length <= 50) {
          return value;
        }
      }
    }
    return null;
  }

  OcrExtractionResult? _extractLabeledDate(String text, List<String> labels) {
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      for (final label in labels) {
        final idx = lower.indexOf(label);
        if (idx < 0) continue;

        for (final segment in [
          lines[i].substring(idx + label.length),
          if (i + 1 < lines.length) lines[i + 1],
        ]) {
          final slice = segment.trim().length > 30
              ? segment.trim().substring(0, 30)
              : segment.trim();
          final parsed = DocumentParser.parseDateFromSegment(slice);
          if (parsed != null) {
            return OcrExtractionResult(
              fieldName: label.contains('purchase') || label.contains('invoice')
                  ? 'issueDate'
                  : 'expiryDate',
              extractedValue: DocumentParser.formatDate(parsed),
              confidence: 85,
            );
          }
        }
      }
    }
    return null;
  }
}
