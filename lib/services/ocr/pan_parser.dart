import 'document_parser.dart';
import 'document_type.dart';
import 'ocr_extraction_result.dart';

class PanParser extends DocumentParser {
  static final _panPattern = RegExp(r'[A-Z]{5}[0-9]{4}[A-Z]{1}');

  @override
  DocumentType get documentType => DocumentType.panCard;

  @override
  List<OcrExtractionResult> parse(String text) {
    final normalized = normalizeText(text);
    final compact = compactText(normalized.toUpperCase());

    return mergeResults([
      extractRegexField(
        compact,
        'documentNumber',
        _panPattern,
        labelKeywords: const [
          'permanent account number',
          'pan',
          'income tax',
        ],
      ),
      extractIssueDate(
        normalized,
        proximityKeywords: const ['issue', 'date of issue'],
      ),
    ]);
  }
}
