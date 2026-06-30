import '../../../../services/ocr/ocr_extraction_result.dart';
import 'base_document_extractor.dart';
import 'extracted_document_fields.dart';

class PassportExtractor extends BaseDocumentExtractor {
  static final _passportNumber = RegExp(r'[A-Z][0-9]{7}');

  static const _numberLabels = [
    'passport no',
    'passport number',
    'passport no.',
    'file no',
    'file number',
  ];

  @override
  String get name => 'PassportExtractor';

  @override
  ExtractedDocumentFields extract(String ocrText) {
    final normalized = normalizeText(ocrText);
    final compact = compactText(normalized.toUpperCase());

    final documentNumber = _extractNearLabels(
          normalized,
          _numberLabels,
          _passportNumber,
        ) ??
        extractRegexField(
          compact,
          'documentNumber',
          _passportNumber,
          labelKeywords: _numberLabels,
        );

    return buildFields(
      title: 'Passport',
      results: mergeResults([
        documentNumber,
        extractIssueDate(
          normalized,
          proximityKeywords: const ['issue', 'date of issue', 'doi', 'place of issue'],
        ),
        extractExpiryDate(
          normalized,
          proximityKeywords: const ['expiry', 'date of expiry', 'valid until', 'doe'],
        ),
        extractAuthority(normalized),
      ]),
    );
  }

  OcrExtractionResult? _extractNearLabels(
    String text,
    List<String> labels,
    RegExp pattern,
  ) {
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final lowerLine = lines[i].toLowerCase();
      for (final label in labels) {
        final idx = lowerLine.indexOf(label);
        if (idx < 0) continue;

        final sameLine = lines[i].substring(idx + label.length);
        final match = pattern.firstMatch(compactText(sameLine.toUpperCase()));
        if (match != null) {
          return OcrExtractionResult(
            fieldName: 'documentNumber',
            extractedValue: match.group(0)!,
            confidence: 92,
          );
        }

        if (i + 1 < lines.length) {
          final nextMatch =
              pattern.firstMatch(compactText(lines[i + 1].toUpperCase()));
          if (nextMatch != null) {
            return OcrExtractionResult(
              fieldName: 'documentNumber',
              extractedValue: nextMatch.group(0)!,
              confidence: 88,
            );
          }
        }
      }
    }
    return null;
  }
}
