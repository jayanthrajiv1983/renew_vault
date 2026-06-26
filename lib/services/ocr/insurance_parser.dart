import 'document_parser.dart';
import 'document_type.dart';
import 'ocr_extraction_result.dart';

class InsuranceParser extends DocumentParser {
  static final _policyPatterns = [
    RegExp(r'[A-Z]{2,4}[-/]?[0-9]{6,12}'),
    RegExp(r'[0-9]{8,15}'),
    RegExp(r'[A-Z0-9]{10,20}'),
  ];

  static final _policyLabels = [
    RegExp(
      r'(?:policy\s*(?:no|number|#)?|certificate\s*no)\s*[:\-]?\s*([A-Z0-9][A-Z0-9\-/]{5,})',
      caseSensitive: false,
    ),
  ];

  @override
  DocumentType get documentType => DocumentType.insurancePolicy;

  @override
  List<OcrExtractionResult> parse(String text) {
    final normalized = normalizeText(text);
    final compact = compactText(normalized.toUpperCase());

    OcrExtractionResult? policyNumber;

    for (final pattern in _policyLabels) {
      final match = pattern.firstMatch(normalized);
      if (match != null) {
        final value = match.group(1)?.trim().toUpperCase();
        if (value != null && value.length >= 6) {
          policyNumber = OcrExtractionResult(
            fieldName: 'documentNumber',
            extractedValue: value,
            confidence: scoreField(
              text: normalized,
              value: value,
              matchStart: match.start,
              matchEnd: match.end,
              labelKeywords: const ['policy', 'certificate'],
              regexMatched: true,
            ),
          );
          break;
        }
      }
    }

    policyNumber ??= _extractFromPatterns(compact, normalized);

    return mergeResults([
      policyNumber,
      extractIssueDate(
        normalized,
        proximityKeywords: const ['issue', 'commencement', 'start'],
      ),
      extractExpiryDate(
        normalized,
        proximityKeywords: const ['expiry', 'valid till', 'renewal'],
      ),
      extractAuthority(normalized),
    ]);
  }

  OcrExtractionResult? _extractFromPatterns(String compact, String raw) {
    for (final pattern in _policyPatterns) {
      final result = extractRegexField(
        compact,
        'documentNumber',
        pattern,
        labelKeywords: const ['policy', 'insurance', 'premium'],
      );
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}
