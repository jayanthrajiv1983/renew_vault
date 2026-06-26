class OcrExtractionResult {
  const OcrExtractionResult({
    required this.fieldName,
    required this.extractedValue,
    required this.confidence,
  });

  final String fieldName;
  final String extractedValue;
  final int confidence;

  bool get isHighConfidence => confidence > 70;

  bool get isAutoApplicable {
    if (fieldName == 'expiryDate') {
      return confidence > 60;
    }
    return confidence > 70;
  }

  OcrExtractionResult copyWith({
    String? fieldName,
    String? extractedValue,
    int? confidence,
  }) {
    return OcrExtractionResult(
      fieldName: fieldName ?? this.fieldName,
      extractedValue: extractedValue ?? this.extractedValue,
      confidence: confidence ?? this.confidence,
    );
  }
}
