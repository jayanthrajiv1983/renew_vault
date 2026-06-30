import '../../../../services/ocr/ocr_extraction_result.dart';

/// Unified output from template-based document extractors.
class ExtractedDocumentFields {
  const ExtractedDocumentFields({
    this.fields = const {},
    this.fieldConfidences = const {},
    this.title,
    this.expiryDate,
    this.documentNumber,
    this.issueDate,
    this.authority,
    this.provider,
    this.purchaseDate,
    this.brand,
    this.model,
    this.amount,
    this.vendor,
    this.invoiceDate,
    this.confidence = 80,
  });

  final Map<String, String> fields;
  final Map<String, int> fieldConfidences;
  final String? title;
  final String? expiryDate;
  final String? documentNumber;
  final String? issueDate;
  final String? authority;
  final String? provider;
  final String? purchaseDate;
  final String? brand;
  final String? model;
  final String? amount;
  final String? vendor;
  final String? invoiceDate;
  final int confidence;

  /// True when at least one primary identifier or expiry was extracted.
  bool get isSufficient =>
      (documentNumber != null && documentNumber!.trim().isNotEmpty) ||
      (expiryDate != null && expiryDate!.trim().isNotEmpty) ||
      (amount != null && amount!.trim().isNotEmpty);

  int get extractedFieldCount {
    var count = 0;
    if (documentNumber != null && documentNumber!.isNotEmpty) count++;
    if (issueDate != null && issueDate!.isNotEmpty) count++;
    if (expiryDate != null && expiryDate!.isNotEmpty) count++;
    if (authority != null && authority!.isNotEmpty) count++;
    if (provider != null && provider!.isNotEmpty) count++;
    if (purchaseDate != null && purchaseDate!.isNotEmpty) count++;
    if (brand != null && brand!.isNotEmpty) count++;
    if (model != null && model!.isNotEmpty) count++;
    if (amount != null && amount!.isNotEmpty) count++;
    if (vendor != null && vendor!.isNotEmpty) count++;
    if (invoiceDate != null && invoiceDate!.isNotEmpty) count++;
    for (final value in fields.values) {
      if (value.trim().isNotEmpty) count++;
    }
    return count;
  }

  int _confidenceFor(String fieldName) {
    return fieldConfidences[fieldName] ?? confidence;
  }

  /// Converts to [OcrExtractionResult] list for the existing OCR pipeline.
  List<OcrExtractionResult> toOcrResults() {
    final results = <OcrExtractionResult>[];
    void add(String fieldName, String? value, {String? confidenceKey}) {
      if (value == null || value.trim().isEmpty) return;
      final key = confidenceKey ?? fieldName;
      results.add(
        OcrExtractionResult(
          fieldName: fieldName,
          extractedValue: value.trim(),
          confidence: _confidenceFor(key),
        ),
      );
    }

    add('documentNumber', documentNumber);
    add('issueDate', issueDate);
    add('expiryDate', expiryDate);
    if (authority != null) {
      add('authority', authority);
    } else if (provider != null) {
      add('authority', provider, confidenceKey: 'provider');
    } else if (vendor != null) {
      add('authority', vendor, confidenceKey: 'vendor');
    }
    add('provider', provider);
    add('purchaseDate', purchaseDate);
    add('brand', brand);
    add('model', model);
    add('amount', amount);
    add('vendor', vendor);
    add('invoiceDate', invoiceDate ?? issueDate, confidenceKey: 'invoiceDate');

    for (final entry in fields.entries) {
      if (results.any((r) => r.fieldName == entry.key)) continue;
      add(entry.key, entry.value);
    }

    return results;
  }
}
