import '../../../../services/ocr/ocr_extraction_result.dart';
import '../document_classifier_service.dart';
import 'base_document_extractor.dart';
import 'extracted_document_fields.dart';

class InsuranceExtractor extends BaseDocumentExtractor {
  static final _policyPatterns = [
    RegExp(r'[A-Z]{2,4}[-/]?[0-9]{6,12}'),
    RegExp(r'[0-9]{8,15}'),
    RegExp(r'[A-Z0-9]{10,20}'),
  ];

  static const _policyLabels = [
    'policy no',
    'policy number',
    'policy no.',
    'certificate no',
    'certificate number',
    'cert no',
  ];

  static const _providerLabels = [
    'insurer',
    'insurance company',
    'underwritten by',
    'issued by',
  ];

  @override
  String get name => 'InsuranceExtractor';

  @override
  ExtractedDocumentFields extract(String ocrText) {
    final normalized = normalizeText(ocrText);
    final compact = compactText(normalized.toUpperCase());

    final policyNumber = _extractPolicyNearLabels(normalized) ??
        _extractFromPatterns(compact, normalized);

    final provider = _extractProvider(normalized);
    final title = _inferTitle(normalized);

    return buildFields(
      title: title,
      provider: provider,
      results: mergeResults([
        policyNumber,
        extractIssueDate(
          normalized,
          proximityKeywords: const ['issue', 'commencement', 'start', 'inception'],
        ),
        extractExpiryDate(
          normalized,
          proximityKeywords: const ['expiry', 'valid till', 'valid upto', 'renewal'],
        ),
        provider != null
            ? OcrExtractionResult(
                fieldName: 'authority',
                extractedValue: provider,
                confidence: 78,
              )
            : extractAuthority(normalized),
      ]),
    );
  }

  String _inferTitle(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('vehicle') ||
        lower.contains('motor') ||
        lower.contains('car insurance')) {
      return DocumentType.vehicleInsurance.displayName;
    }
    if (lower.contains('health') || lower.contains('mediclaim')) {
      return DocumentType.healthInsurance.displayName;
    }
    if (lower.contains('life insurance') || lower.contains('sum assured')) {
      return DocumentType.lifeInsurance.displayName;
    }
    if (lower.contains('travel insurance') || lower.contains('trip')) {
      return DocumentType.travelInsurance.displayName;
    }
    return 'Insurance Policy';
  }

  OcrExtractionResult? _extractPolicyNearLabels(String text) {
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final lowerLine = lines[i].toLowerCase();
      for (final label in _policyLabels) {
        final idx = lowerLine.indexOf(label);
        if (idx < 0) continue;

        for (final segment in [
          lines[i].substring(idx + label.length),
          if (i + 1 < lines.length) lines[i + 1],
        ]) {
          final cleaned = segment.trim().replaceFirst(RegExp(r'^[:\-\.\s]+'), '');
          if (cleaned.length < 6) continue;

          for (final pattern in _policyPatterns) {
            final match = pattern.firstMatch(cleaned.toUpperCase());
            if (match != null) {
              return OcrExtractionResult(
                fieldName: 'documentNumber',
                extractedValue: match.group(0)!,
                confidence: 90,
              );
            }
          }

          final token = cleaned.split(RegExp(r'\s+')).first;
          if (token.length >= 6 && RegExp(r'^[A-Z0-9\-/]+$').hasMatch(token.toUpperCase())) {
            return OcrExtractionResult(
              fieldName: 'documentNumber',
              extractedValue: token.toUpperCase(),
              confidence: 82,
            );
          }
        }
      }
    }
    return null;
  }

  OcrExtractionResult? _extractFromPatterns(String compact, String raw) {
    for (final pattern in _policyPatterns) {
      final result = extractRegexField(
        compact,
        'documentNumber',
        pattern,
        labelKeywords: const ['policy', 'insurance', 'premium', 'certificate'],
      );
      if (result != null) return result;
    }
    return null;
  }

  String? _extractProvider(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      final lower = line.toLowerCase();
      for (final label in _providerLabels) {
        final idx = lower.indexOf(label);
        if (idx < 0) continue;
        final value = line.substring(idx + label.length).trim();
        final cleaned = value.replaceFirst(RegExp(r'^[:\-\.\s]+'), '').trim();
        if (cleaned.length >= 3 && cleaned.length <= 60) {
          return cleaned;
        }
      }
    }
    return null;
  }
}
