import 'document_parser.dart';
import 'document_type.dart';
import 'ocr_extraction_result.dart';

class VehicleRcParser extends DocumentParser {
  static final _registrationPattern =
      RegExp(r'[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}');

  @override
  DocumentType get documentType => DocumentType.vehicleRc;

  @override
  List<OcrExtractionResult> parse(String text) {
    final normalized = normalizeText(text);
    final compact = compactText(normalized.toUpperCase());

    return mergeResults([
      extractRegexField(
        compact,
        'documentNumber',
        _registrationPattern,
        labelKeywords: const [
          'registration no',
          'registration number',
          'reg no',
          'rc no',
        ],
      ),
      extractIssueDate(
        normalized,
        proximityKeywords: const ['issue', 'registration date'],
      ),
      extractExpiryDate(
        normalized,
        proximityKeywords: const ['valid', 'expiry', 'fitness'],
      ),
      extractAuthority(normalized),
    ]);
  }
}
