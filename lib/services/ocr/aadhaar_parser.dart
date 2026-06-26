import 'document_parser.dart';
import 'document_type.dart';
import 'ocr_extraction_result.dart';

class AadhaarParser extends DocumentParser {
  static final _aadhaarSpaced = RegExp(r'[0-9]{4}\s[0-9]{4}\s[0-9]{4}');
  static final _aadhaarCompact = RegExp(r'[0-9]{12}');

  @override
  DocumentType get documentType => DocumentType.aadhaarCard;

  @override
  List<OcrExtractionResult> parse(String text) {
    final normalized = normalizeText(text);

    final spaced = extractRegexField(
      normalized,
      'documentNumber',
      _aadhaarSpaced,
      labelKeywords: const ['aadhaar', 'aadhar', 'uid', 'enrolment'],
    );

    final compact = spaced ??
        extractRegexField(
          compactText(normalized),
          'documentNumber',
          _aadhaarCompact,
          labelKeywords: const ['aadhaar', 'aadhar', 'uid'],
          transform: (raw) {
            if (raw.length != 12) {
              return raw;
            }
            return '${raw.substring(0, 4)} ${raw.substring(4, 8)} ${raw.substring(8)}';
          },
        );

    return mergeResults([compact]);
  }
}
