import '../../../../services/ocr/ocr_extraction_result.dart';
import 'base_document_extractor.dart';
import 'extracted_document_fields.dart';

class DrivingLicenceExtractor extends BaseDocumentExtractor {
  static final _dlPattern15 = RegExp(r'[A-Z]{2}[0-9]{2}\s?[0-9]{11}');
  static final _dlPattern13 = RegExp(r'[A-Z]{2}[0-9]{13}');

  static const _numberLabels = [
    'dl no',
    'dl. no.',
    'dl. no',
    'dl number',
    'licence no',
    'license no',
    'licence number',
    'license number',
  ];

  static const _ignorePhrases = [
    'VALID THROUGHOUT INDIA',
  ];

  @override
  String get name => 'DrivingLicenceExtractor';

  @override
  ExtractedDocumentFields extract(String ocrText) {
    final normalized = normalizeText(ocrText);
    final compact = compactText(normalized.toUpperCase());

    final documentNumber = _extractNearLabels(normalized) ??
        extractRegexField(
          compact,
          'documentNumber',
          _dlPattern15,
          labelKeywords: _numberLabels,
          ignoreMatchesNear: true,
          ignorePhrases: _ignorePhrases,
          transform: (raw) => raw.replaceAll(' ', ''),
        ) ??
        extractRegexField(
          compact,
          'documentNumber',
          _dlPattern13,
          labelKeywords: _numberLabels,
          ignoreMatchesNear: true,
          ignorePhrases: _ignorePhrases,
        );

    return buildFields(
      title: 'Driving Licence',
      results: mergeResults([
        documentNumber,
        extractIssueDate(
          normalized,
          proximityKeywords: const ['issue', 'doi', 'date of issue'],
        ),
        extractExpiryDate(
          normalized,
          proximityKeywords: const ['valid', 'expiry', 'valid till', 'valid upto'],
        ),
        extractAuthority(normalized),
      ]),
    );
  }

  OcrExtractionResult? _extractNearLabels(String text) {
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final lowerLine = lines[i].toLowerCase();
      for (final label in _numberLabels) {
        final idx = lowerLine.indexOf(label);
        if (idx < 0) continue;

        final segments = [
          lines[i].substring(idx + label.length),
          if (i + 1 < lines.length) lines[i + 1],
        ];

        for (final segment in segments) {
          final upper = compactText(segment.toUpperCase());
          if (_ignorePhrases.any((phrase) => upper.contains(phrase))) {
            continue;
          }

          final match15 = _dlPattern15.firstMatch(upper);
          if (match15 != null) {
            return OcrExtractionResult(
              fieldName: 'documentNumber',
              extractedValue: match15.group(0)!.replaceAll(' ', ''),
              confidence: 93,
            );
          }

          final match13 = _dlPattern13.firstMatch(upper);
          if (match13 != null) {
            return OcrExtractionResult(
              fieldName: 'documentNumber',
              extractedValue: match13.group(0)!,
              confidence: 90,
            );
          }
        }
      }
    }
    return null;
  }
}
