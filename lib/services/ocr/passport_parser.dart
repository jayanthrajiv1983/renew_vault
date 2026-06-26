import 'document_parser.dart';
import 'document_type.dart';
import 'ocr_extraction_result.dart';

class PassportParser extends DocumentParser {
  static final _passportNumber = RegExp(r'[A-Z][0-9]{7}');

  @override
  DocumentType get documentType => DocumentType.passport;

  @override
  List<OcrExtractionResult> parse(String text) {
    final normalized = normalizeText(text);
    final compact = compactText(normalized.toUpperCase());

    return mergeResults([
      extractRegexField(
        compact,
        'documentNumber',
        _passportNumber,
        labelKeywords: const [
          'passport no',
          'passport number',
          'file no',
        ],
      ),
      extractIssueDate(
        normalized,
        proximityKeywords: const ['issue', 'date of issue', 'doi'],
      ),
      extractExpiryDate(
        normalized,
        proximityKeywords: const ['expiry', 'date of expiry', 'valid until'],
      ),
      extractAuthority(normalized),
    ]);
  }
}
