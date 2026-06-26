import 'package:hive_flutter/hive_flutter.dart';

import '../models/ocr_correction.dart';
import 'ocr/ocr_extraction_result.dart';

/// On-device OCR correction learning. Stores user corrections locally in Hive.
class OcrCorrectionService {
  OcrCorrectionService._();

  static final OcrCorrectionService instance = OcrCorrectionService._();

  static const _boxName = 'ocr_corrections';
  static const _learnedConfidenceBoost = 15;
  static const _learnedConfidenceCap = 95;

  Box? _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _box = await Hive.openBox(_boxName);
    _initialized = true;
  }

  static String _storageKey(String fieldName, String originalValue) {
    return '$fieldName::${originalValue.trim()}';
  }

  /// Records or reinforces a user correction for future OCR suggestions.
  Future<void> recordCorrection(
    String fieldName,
    String original,
    String corrected, {
    String? documentType,
  }) async {
    final trimmedOriginal = original.trim();
    final trimmedCorrected = corrected.trim();
    if (trimmedOriginal.isEmpty ||
        trimmedCorrected.isEmpty ||
        trimmedOriginal == trimmedCorrected) {
      return;
    }

    final key = _storageKey(fieldName, trimmedOriginal);
    final existing = _box?.get(key);
    if (existing != null) {
      final prior = OcrCorrection.fromJson(
        Map<String, dynamic>.from(existing as Map),
      );
      await _box?.put(
        key,
        prior
            .copyWith(
              correctedValue: trimmedCorrected,
              documentType: documentType ?? prior.documentType,
              usageCount: prior.usageCount + 1,
              updatedAt: DateTime.now(),
            )
            .toJson(),
      );
      return;
    }

    await _box?.put(
      key,
      OcrCorrection(
        fieldName: fieldName,
        originalValue: trimmedOriginal,
        correctedValue: trimmedCorrected,
        documentType: documentType,
        updatedAt: DateTime.now(),
      ).toJson(),
    );
  }

  /// Returns a previously learned correction for [ocrValue], if one exists.
  String? getSuggestion(
    String fieldName,
    String ocrValue, {
    String? documentType,
  }) {
    final trimmed = ocrValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final exact = _lookupExact(fieldName, trimmed);
    if (exact != null) {
      return _preferDocumentType([exact], documentType)?.correctedValue;
    }

    final fuzzy = _lookupFuzzy(fieldName, trimmed, documentType: documentType);
    return fuzzy?.correctedValue;
  }

  /// Applies learned corrections to OCR fields before review / apply.
  List<OcrExtractionResult> applyLearnedCorrections(
    List<OcrExtractionResult> fields, {
    String? documentType,
  }) {
    return fields.map((field) {
      final suggestion = getSuggestion(
        field.fieldName,
        field.extractedValue,
        documentType: documentType,
      );
      if (suggestion == null || suggestion == field.extractedValue) {
        return field;
      }

      final boosted = (field.confidence + _learnedConfidenceBoost)
          .clamp(0, _learnedConfidenceCap);
      return field.copyWith(
        extractedValue: suggestion,
        confidence: boosted,
      );
    }).toList();
  }

  /// Whether [field]'s value came from a learned correction (for UI hints).
  bool wasLearnedCorrection(
    OcrExtractionResult field, {
    String? documentType,
    String? rawOcrValue,
  }) {
    final ocrValue = rawOcrValue ?? field.extractedValue;
    final suggestion = getSuggestion(
      field.fieldName,
      ocrValue,
      documentType: documentType,
    );
    return suggestion != null && suggestion == field.extractedValue;
  }

  OcrCorrection? _lookupExact(String fieldName, String ocrValue) {
    final stored = _box?.get(_storageKey(fieldName, ocrValue));
    if (stored == null) {
      return null;
    }
    return OcrCorrection.fromJson(Map<String, dynamic>.from(stored as Map));
  }

  OcrCorrection? _lookupFuzzy(
    String fieldName,
    String ocrValue, {
    String? documentType,
  }) {
    final box = _box;
    if (box == null || box.isEmpty) {
      return null;
    }

    OcrCorrection? best;
    var bestDistance = _maxFuzzyDistance(ocrValue);

    for (final key in box.keys) {
      if (key is! String || !key.startsWith('$fieldName::')) {
        continue;
      }
      final stored = box.get(key);
      if (stored is! Map) {
        continue;
      }
      final correction = OcrCorrection.fromJson(
        Map<String, dynamic>.from(stored),
      );
      if (correction.fieldName != fieldName) {
        continue;
      }

      final distance = _ocrAwareDistance(
        _normalizeForCompare(ocrValue),
        _normalizeForCompare(correction.originalValue),
      );
      if (distance > _maxFuzzyDistance(ocrValue)) {
        continue;
      }

      final typed = _preferDocumentType([correction], documentType);
      if (typed == null) {
        continue;
      }

      if (best == null || distance < bestDistance) {
        best = typed;
        bestDistance = distance;
      } else if (distance == bestDistance &&
          typed.usageCount > (best.usageCount)) {
        best = typed;
      }
    }

    return best;
  }

  OcrCorrection? _preferDocumentType(
    List<OcrCorrection> candidates,
    String? documentType,
  ) {
    if (candidates.isEmpty) {
      return null;
    }
    if (documentType != null) {
      final typed = candidates.where(
        (c) => c.documentType == documentType,
      );
      if (typed.isNotEmpty) {
        return typed.reduce(
          (a, b) => a.usageCount >= b.usageCount ? a : b,
        );
      }
    }
    return candidates.reduce(
      (a, b) => a.usageCount >= b.usageCount ? a : b,
    );
  }

  static int _maxFuzzyDistance(String value) {
    final len = value.length;
    if (len <= 4) {
      return 1;
    }
    if (len <= 8) {
      return 2;
    }
    return 3;
  }

  static String _normalizeForCompare(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  /// Levenshtein distance with common OCR character equivalences.
  static int _ocrAwareDistance(String a, String b) {
    if (a == b) {
      return 0;
    }

    final equivA = _applyOcrEquivalences(a);
    final equivB = _applyOcrEquivalences(b);
    if (equivA == equivB) {
      return 0;
    }

    return _levenshtein(equivA, equivB);
  }

  static String _applyOcrEquivalences(String value) {
    const substitutions = {
      '0': 'O',
      '1': 'I',
      '5': 'S',
      '8': 'B',
      '|': 'I',
      '!': 'I',
    };
    final buffer = StringBuffer();
    for (final char in value.split('')) {
      buffer.write(substitutions[char] ?? char);
    }
    return buffer.toString();
  }

  static int _levenshtein(String a, String b) {
    if (a.isEmpty) {
      return b.length;
    }
    if (b.isEmpty) {
      return a.length;
    }

    var previous = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 0; i < a.length; i++) {
      var current = List<int>.filled(b.length + 1, 0);
      current[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        current[j + 1] = [
          current[j] + 1,
          previous[j + 1] + 1,
          previous[j] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      previous = current;
    }
    return previous[b.length];
  }
}
