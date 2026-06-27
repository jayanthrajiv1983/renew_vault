import 'document_type.dart';
import 'ocr_engine.dart';
import 'ocr_extraction_result.dart';

/// User-confirmed values from the OCR review step.
class OcrReviewData {
  const OcrReviewData({
    required this.title,
    required this.category,
    this.documentNumber,
    this.issueDate,
    this.expiryDate,
    this.authority,
    required this.documentTypeKey,
    required this.rawOcrValues,
  });

  final String title;
  final String category;
  final String? documentNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? authority;
  final String documentTypeKey;
  final Map<String, String> rawOcrValues;
}

/// Maps OCR engine output to renewal form fields.
abstract final class OcrFormMapper {
  static String inferTitle(OcrEngineResult result) {
    if (result.documentType != DocumentType.unknown) {
      return result.documentType.label;
    }
    return 'Scanned Document';
  }

  static String inferCategory(
    OcrEngineResult result, {
    required List<String> allowedCategories,
    String? fallback,
  }) {
    final category = switch (result.documentType) {
      DocumentType.vehicleRc => 'Vehicle',
      DocumentType.insurancePolicy => 'Insurance',
      DocumentType.drivingLicense ||
      DocumentType.passport ||
      DocumentType.panCard ||
      DocumentType.aadhaarCard ||
      DocumentType.unknown =>
        'Document',
    };
    if (allowedCategories.contains(category)) {
      return category;
    }
    return fallback ?? allowedCategories.first;
  }

  static String? fieldValue(OcrEngineResult result, String fieldName) {
    return result.fieldNamed(fieldName)?.extractedValue;
  }

  static DateTime? parseOcrDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
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

  static String fieldLabel(String fieldName) {
    switch (fieldName) {
      case 'documentNumber':
        return 'Document Number';
      case 'issueDate':
        return 'Issue Date';
      case 'expiryDate':
        return 'Expiry Date';
      case 'authority':
        return 'Authority';
      default:
        return fieldName;
    }
  }

  static Map<String, String> rawValuesFrom(OcrEngineResult result) {
    return {
      for (final field in result.fields) field.fieldName: field.extractedValue,
    };
  }

  static OcrReviewData initialReviewData(
    OcrEngineResult result, {
    required Map<String, String> rawOcrValues,
    required List<String> allowedCategories,
    String? currentCategory,
  }) {
    return OcrReviewData(
      title: inferTitle(result),
      category: inferCategory(
        result,
        allowedCategories: allowedCategories,
        fallback: currentCategory,
      ),
      documentNumber: fieldValue(result, 'documentNumber'),
      issueDate: parseOcrDate(fieldValue(result, 'issueDate')),
      expiryDate: parseOcrDate(fieldValue(result, 'expiryDate')),
      authority: fieldValue(result, 'authority'),
      documentTypeKey: result.documentType.name,
      rawOcrValues: rawOcrValues,
    );
  }

  static bool isLowConfidence(OcrExtractionResult field) {
    return !field.isAutoApplicable;
  }
}
