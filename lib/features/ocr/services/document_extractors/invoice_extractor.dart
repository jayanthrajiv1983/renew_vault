import '../../../../services/ocr/ocr_extraction_result.dart';
import 'base_document_extractor.dart';
import 'extracted_document_fields.dart';

class InvoiceExtractor extends BaseDocumentExtractor {
  static final _amountPattern = RegExp(
    r'(?:total|grand\s*total|amount\s*due|net\s*amount|payable)\s*[:\-]?\s*(?:rs\.?|inr|₹)?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final _invoiceNumberPattern = RegExp(
    r'(?:invoice\s*(?:no|number|#)|bill\s*(?:no|number|#))\s*[:\-]?\s*([A-Z0-9][A-Z0-9\-/]{3,})',
    caseSensitive: false,
  );

  static const _vendorHints = [
    'sold by',
    'vendor',
    'supplier',
    'from',
    'billed by',
  ];

  @override
  String get name => 'InvoiceExtractor';

  @override
  ExtractedDocumentFields extract(String ocrText) {
    final normalized = normalizeText(ocrText);
    final amountResult = _extractAmount(normalized);
    final invoiceNumber = _extractInvoiceNumber(normalized);
    final vendor = _extractVendor(normalized);
    final invoiceDate = extractIssueDate(
      normalized,
      proximityKeywords: const ['invoice date', 'bill date', 'date', 'dated'],
    );

    return buildFields(
      title: 'Invoice',
      vendor: vendor,
      invoiceDate: invoiceDate?.extractedValue,
      results: mergeResults([
        invoiceNumber,
        invoiceDate,
        amountResult,
      ]),
    );
  }

  OcrExtractionResult? _extractAmount(String text) {
    final match = _amountPattern.firstMatch(text);
    if (match != null) {
      final value = match.group(1)?.replaceAll(',', '');
      if (value == null || value.isEmpty) return null;
      return OcrExtractionResult(
        fieldName: 'amount',
        extractedValue: value,
        confidence: 84,
      );
    }

    final lines = text.split('\n');
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('total') || lower.contains('amount')) {
        final numMatch = RegExp(r'([0-9,]+(?:\.[0-9]{1,2})?)').firstMatch(line);
        if (numMatch != null) {
          return OcrExtractionResult(
            fieldName: 'amount',
            extractedValue: numMatch.group(1)!.replaceAll(',', ''),
            confidence: 55,
          );
        }
      }
    }
    return null;
  }

  OcrExtractionResult? _extractInvoiceNumber(String text) {
    final match = _invoiceNumberPattern.firstMatch(text);
    if (match != null) {
      return OcrExtractionResult(
        fieldName: 'documentNumber',
        extractedValue: match.group(1)!.trim().toUpperCase(),
        confidence: 84,
      );
    }

    final lines = text.split('\n');
    const labels = ['invoice no', 'invoice number', 'bill no', 'bill number'];
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
        if (value.length >= 3) {
          return OcrExtractionResult(
            fieldName: 'documentNumber',
            extractedValue: value.split(RegExp(r'\s+')).first.toUpperCase(),
            confidence: 82,
          );
        }
      }
    }
    return null;
  }

  String? _extractVendor(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      final lower = line.toLowerCase();
      for (final hint in _vendorHints) {
        final idx = lower.indexOf(hint);
        if (idx < 0) continue;
        final value = line
            .substring(idx + hint.length)
            .trim()
            .replaceFirst(RegExp(r'^[:\-\.\s]+'), '')
            .trim();
        if (value.length >= 3 && value.length <= 60) {
          return value;
        }
      }
    }

    if (lines.isNotEmpty) {
      final first = lines.first.trim();
      if (first.length >= 3 && first.length <= 60 && !first.toLowerCase().contains('invoice')) {
        return first;
      }
    }
    return null;
  }
}
