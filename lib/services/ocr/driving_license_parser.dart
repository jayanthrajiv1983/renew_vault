import 'document_parser.dart';
import 'document_type.dart';
import 'ocr_extraction_result.dart';

class DrivingLicenseParser extends DocumentParser {
  static final _dlPattern15 = RegExp(r'[A-Z]{2}[0-9]{2}[0-9]{11}');
  static final _dlPattern13 = RegExp(r'[A-Z]{2}[0-9]{13}');

  static const _ignorePhrases = [
    'VALID THROUGHOUT INDIA',
    'TRANSPORT',
  ];

  @override
  DocumentType get documentType => DocumentType.drivingLicense;

  @override
  List<OcrExtractionResult> parse(String text) {
    final normalized = normalizeText(text);
    final compact = compactText(normalized.toUpperCase());

    final documentNumber = extractRegexField(
      compact,
      'documentNumber',
      _dlPattern15,
      labelKeywords: const ['dl no', 'licence no', 'license no', 'dl number'],
      ignoreMatchesNear: true,
      ignorePhrases: _ignorePhrases,
    ) ??
        extractRegexField(
          compact,
          'documentNumber',
          _dlPattern13,
          labelKeywords: const ['dl no', 'licence no', 'license no'],
          ignoreMatchesNear: true,
          ignorePhrases: _ignorePhrases,
        );

    return mergeResults([
      documentNumber,
      extractIssueDate(
        normalized,
        proximityKeywords: const ['issue', 'doi', 'date of issue'],
      ),
      extractExpiryDate(
        normalized,
        proximityKeywords: const ['valid', 'expiry', 'nt'],
      ),
      extractAuthority(normalized),
    ]);
  }
}
