import 'dart:math' as math;

import 'document_type.dart';
import 'ocr_extraction_result.dart';

abstract class DocumentParser {
  DocumentType get documentType;

  List<OcrExtractionResult> parse(String text);

  String normalizeText(String text) {
    return text.replaceAll('\r\n', '\n');
  }

  String compactText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static const _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  static final _numericDate = RegExp(
    r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})',
  );

  static final _isoDate = RegExp(r'(\d{4})-(\d{2})-(\d{2})');

  static final _textMonthDate = RegExp(
    r'(\d{1,2})[\s\-](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s\-](\d{2,4})',
    caseSensitive: false,
  );

  static final _issueDateLabels = [
    RegExp(
      r'(?:date\s*of\s*issue|issue\s*date|issued\s*(?:on|date)?|doi)\s*[:\-]?\s*([^\n]{4,30})',
      caseSensitive: false,
    ),
  ];

  static final _expiryDateLabels = [
    RegExp(
      r'(?:expir(?:y|es|ation)|valid\s*(?:until|till|upto|up\s*to|ity)|date\s*of\s*expiry|expires\s*on|doe)\s*[:\-]?\s*([^\n]{4,30})',
      caseSensitive: false,
    ),
  ];

  static const _birthContextLabels = [
    'date of birth',
    'd.o.b',
    'dob',
    'birth date',
    'born on',
    'birth',
  ];

  static const _issueContextLabels = [
    'date of issue',
    'issue date',
    'issued on',
    'issued',
    'issue',
    'doi',
  ];

  static const _expiryContextLabels = [
    'expiry date',
    'date of expiry',
    'expires on',
    'expires',
    'valid until',
    'valid till',
    'valid upto',
    'valid up to',
    'validity',
    'expiry',
    'expiration',
    'doe',
  ];

  static final _authorityLabels = [
    RegExp(
      r'(?:issuing\s*authority|licensing\s*authority|authority|issued\s*by|rto)\s*[:\-]?\s*([^\n]{3,60})',
      caseSensitive: false,
    ),
  ];

  OcrExtractionResult? extractLabeledDate(
    String text,
    String fieldName,
    List<RegExp> labels, {
    List<String> proximityKeywords = const [],
  }) {
    for (final pattern in labels) {
      final match = pattern.firstMatch(text);
      if (match == null) {
        continue;
      }
      final segment = match.group(1)?.trim();
      if (segment == null) {
        continue;
      }
      final parsed = parseDateFromSegment(segment);
      if (parsed == null) {
        continue;
      }
      final formatted = formatDate(parsed);
      final confidence = scoreField(
        text: text,
        value: formatted,
        matchStart: match.start,
        matchEnd: match.end,
        labelKeywords: proximityKeywords,
        regexMatched: true,
      );
      return OcrExtractionResult(
        fieldName: fieldName,
        extractedValue: formatted,
        confidence: confidence,
      );
    }
    return null;
  }

  OcrExtractionResult? extractRegexField(
    String text,
    String fieldName,
    RegExp pattern, {
    List<String> labelKeywords = const [],
    int group = 0,
    String Function(String raw)? transform,
    bool ignoreMatchesNear = false,
    List<String> ignorePhrases = const [],
  }) {
    final normalized = compactText(text.toUpperCase());
    final matches = pattern.allMatches(normalized);

    for (final match in matches) {
      final raw = match.group(group)?.trim();
      if (raw == null || raw.isEmpty) {
        continue;
      }

      if (ignoreMatchesNear && ignorePhrases.isNotEmpty) {
        final contextStart = math.max(0, match.start - 40);
        final contextEnd = math.min(normalized.length, match.end + 40);
        final context = normalized.substring(contextStart, contextEnd);
        if (ignorePhrases.any(
          (phrase) => context.contains(phrase.toUpperCase()),
        )) {
          continue;
        }
      }

      final value = transform?.call(raw) ?? raw;
      final confidence = scoreField(
        text: text,
        value: value,
        matchStart: match.start,
        matchEnd: match.end,
        labelKeywords: labelKeywords,
        regexMatched: true,
      );
      return OcrExtractionResult(
        fieldName: fieldName,
        extractedValue: value,
        confidence: confidence,
      );
    }
    return null;
  }

  OcrExtractionResult? extractAuthority(String text) {
    for (final pattern in _authorityLabels) {
      final match = pattern.firstMatch(text);
      if (match == null) {
        continue;
      }
      final value = match.group(1)?.trim();
      if (value == null || value.length < 3) {
        continue;
      }
      final confidence = scoreField(
        text: text,
        value: value,
        matchStart: match.start,
        matchEnd: match.end,
        labelKeywords: const ['authority', 'issued by', 'rto'],
        regexMatched: true,
      );
      return OcrExtractionResult(
        fieldName: 'authority',
        extractedValue: value,
        confidence: confidence,
      );
    }
    return null;
  }

  OcrExtractionResult? extractIssueDate(
    String text, {
    List<String> proximityKeywords = const ['issue', 'doi'],
  }) {
    final normalized = normalizeText(text);
    final categorizedDates = extractDates(normalized);
    _logCategorizedDates(categorizedDates);

    OcrExtractionResult? selected = extractLabeledDate(
      normalized,
      'issueDate',
      _issueDateLabels,
      proximityKeywords: proximityKeywords,
    );

    selected ??= _extractIssueViaLabelProximity(normalized);

    selected ??= _selectIssueFromCategorizedDates(normalized, categorizedDates);

    return selected;
  }

  OcrExtractionResult? extractExpiryDate(
    String text, {
    List<String> proximityKeywords = const [
      'expiry',
      'valid',
      'validity',
      'expires',
      'doe',
    ],
  }) {
    final normalized = normalizeText(text);
    final categorizedDates = extractDates(normalized);
    _logCategorizedDates(categorizedDates);

    OcrExtractionResult? selected = extractLabeledDate(
      normalized,
      'expiryDate',
      _expiryDateLabels,
      proximityKeywords: proximityKeywords,
    );

    selected ??= _extractExpiryViaLabelProximity(normalized);

    selected ??= _selectExpiryFromCategorizedDates(
      normalized,
      categorizedDates,
      excludeFormatted: _resolveIssueDateFormatted(normalized, categorizedDates),
    );

    return selected;
  }

  String? _resolveIssueDateFormatted(
    String text,
    List<CategorizedDate> categorizedDates,
  ) {
    final labeled = extractLabeledDate(text, 'issueDate', _issueDateLabels);
    if (labeled != null) {
      return labeled.extractedValue;
    }

    final proximity = _extractIssueViaLabelProximity(text);
    if (proximity != null) {
      return proximity.extractedValue;
    }

    final issueLabeled = categorizedDates
        .where((match) => match.type == DateCategory.issueDate)
        .toList();
    if (issueLabeled.isEmpty) {
      return null;
    }
    issueLabeled.sort((a, b) => a.date.compareTo(b.date));
    return issueLabeled.last.formatted;
  }

  /// Extracts every date match in [text] with birth/issue/expiry classification.
  static List<CategorizedDate> extractDates(String text) {
    final matches = <CategorizedDate>[];
    final seen = <String>{};

    void addMatch(DateTime? date, int start, int end, String raw) {
      if (date == null) {
        return;
      }
      final formatted = formatDate(date);
      final key = '$start:$formatted';
      if (seen.contains(key)) {
        return;
      }
      seen.add(key);
      matches.add(
        CategorizedDate(
          date: date,
          formatted: formatted,
          start: start,
          end: end,
          type: _classifyDateContext(text, start),
        ),
      );
    }

    for (final match in _isoDate.allMatches(text)) {
      addMatch(
        buildDate(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        ),
        match.start,
        match.end,
        match.group(0)!,
      );
    }

    for (final match in _textMonthDate.allMatches(text)) {
      final monthKey = match.group(2)!.toLowerCase().substring(0, 3);
      final month = _months[monthKey];
      if (month == null) {
        continue;
      }
      addMatch(
        buildDate(
          normalizeYear(int.parse(match.group(3)!)),
          month,
          int.parse(match.group(1)!),
        ),
        match.start,
        match.end,
        match.group(0)!,
      );
    }

    for (final match in _numericDate.allMatches(text)) {
      final a = int.parse(match.group(1)!);
      final b = int.parse(match.group(2)!);
      final c = normalizeYear(int.parse(match.group(3)!));
      addMatch(parseNumericDate(a, b, c), match.start, match.end, match.group(0)!);
    }

    matches.sort((a, b) => a.start.compareTo(b.start));
    return matches;
  }

  static DateCategory _classifyDateContext(String text, int matchStart) {
    final windowStart = math.max(0, matchStart - 70);
    final windowEnd = math.min(text.length, matchStart + 30);
    final context = text.substring(windowStart, windowEnd).toLowerCase();

    if (_contextContainsAny(context, _birthContextLabels)) {
      return DateCategory.birthDate;
    }
    if (_contextContainsAny(context, _issueContextLabels)) {
      return DateCategory.issueDate;
    }
    if (_contextContainsAny(context, _expiryContextLabels)) {
      return DateCategory.expiryDate;
    }
    return DateCategory.unknown;
  }

  static bool _contextContainsAny(String context, List<String> labels) {
    for (final label in labels) {
      if (context.contains(label)) {
        return true;
      }
    }
    return false;
  }

  OcrExtractionResult? _extractIssueViaLabelProximity(String text) {
    final lines = text.split('\n');
    final rule = _labelProximityRules.firstWhere(
      (entry) => entry.fieldName == 'issueDate',
    );
    return _extractNearLabel(lines, text, rule);
  }

  OcrExtractionResult? _extractExpiryViaLabelProximity(String text) {
    final lines = text.split('\n');
    final rule = _labelProximityRules.firstWhere(
      (entry) => entry.fieldName == 'expiryDate',
    );
    return _extractNearLabel(lines, text, rule);
  }

  OcrExtractionResult? _selectIssueFromCategorizedDates(
    String text,
    List<CategorizedDate> categorizedDates,
  ) {
    final issueLabeled = categorizedDates
        .where((match) => match.type == DateCategory.issueDate)
        .toList();
    if (issueLabeled.isEmpty) {
      return null;
    }

    issueLabeled.sort((a, b) => a.date.compareTo(b.date));
    final selected = issueLabeled.last;
    return OcrExtractionResult(
      fieldName: 'issueDate',
      extractedValue: selected.formatted,
      confidence: scoreField(
        text: text,
        value: selected.formatted,
        matchStart: selected.start,
        matchEnd: selected.end,
        labelKeywords: _issueContextLabels,
        regexMatched: true,
      ),
    );
  }

  OcrExtractionResult? _selectExpiryFromCategorizedDates(
    String text,
    List<CategorizedDate> categorizedDates, {
    String? excludeFormatted,
  }) {
    final today = _todayDateOnly();
    final candidates = categorizedDates.where((match) {
      if (match.type == DateCategory.issueDate ||
          match.type == DateCategory.birthDate) {
        return false;
      }
      if (excludeFormatted != null && match.formatted == excludeFormatted) {
        return false;
      }
      if (match.date.isBefore(today)) {
        return false;
      }
      return true;
    }).toList();

    if (candidates.isEmpty) {
      return null;
    }

    final expiryLabeled = candidates
        .where((match) => match.type == DateCategory.expiryDate)
        .toList();
    if (expiryLabeled.isNotEmpty) {
      expiryLabeled.sort((a, b) => a.date.compareTo(b.date));
      final selected = expiryLabeled.last;
      return OcrExtractionResult(
        fieldName: 'expiryDate',
        extractedValue: selected.formatted,
        confidence: scoreField(
          text: text,
          value: selected.formatted,
          matchStart: selected.start,
          matchEnd: selected.end,
          labelKeywords: _expiryContextLabels,
          regexMatched: true,
        ),
      );
    }

    final futureDates = candidates
        .where((match) => match.date.isAfter(today))
        .toList();
    if (futureDates.isEmpty) {
      return null;
    }

    futureDates.sort((a, b) => a.date.compareTo(b.date));
    final selected = futureDates.last;
    return OcrExtractionResult(
      fieldName: 'expiryDate',
      extractedValue: selected.formatted,
      confidence: 65,
    );
  }

  static DateTime _todayDateOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static void _logCategorizedDates(List<CategorizedDate> categorizedDates) {
    // Intentionally no-op: date values must not be logged.
  }

  int scoreField({
    required String text,
    required String value,
    required int matchStart,
    required int matchEnd,
    List<String> labelKeywords = const [],
    bool regexMatched = false,
  }) {
    var confidence = regexMatched ? 72 : 50;

    final lowerText = text.toLowerCase();
    for (final keyword in labelKeywords) {
      final keywordIndex = lowerText.indexOf(keyword.toLowerCase());
      if (keywordIndex < 0) {
        continue;
      }
      final distance = (keywordIndex - matchStart).abs();
      if (distance <= 40) {
        confidence += 20;
      } else if (distance <= 80) {
        confidence += 12;
      } else if (distance <= 150) {
        confidence += 6;
      }
    }

    if (value.length >= 6) {
      confidence += 4;
    }

    return confidence.clamp(0, 100);
  }

  static int scoreDocumentType(String text, List<String> keywords) {
    final lower = text.toLowerCase();
    var score = 0;
    for (final keyword in keywords) {
      if (lower.contains(keyword.toLowerCase())) {
        score++;
      }
    }
    return score;
  }

  static DateTime? parseDateFromSegment(String segment) {
    final iso = _isoDate.firstMatch(segment);
    if (iso != null) {
      return buildDate(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }

    final textMonth = _textMonthDate.firstMatch(segment);
    if (textMonth != null) {
      final monthKey = textMonth.group(2)!.toLowerCase().substring(0, 3);
      final month = _months[monthKey];
      if (month != null) {
        return buildDate(
          normalizeYear(int.parse(textMonth.group(3)!)),
          month,
          int.parse(textMonth.group(1)!),
        );
      }
    }

    final numeric = _numericDate.firstMatch(segment);
    if (numeric != null) {
      final a = int.parse(numeric.group(1)!);
      final b = int.parse(numeric.group(2)!);
      final c = normalizeYear(int.parse(numeric.group(3)!));
      return parseNumericDate(a, b, c);
    }

    return null;
  }

  static DateTime? parseNumericDate(int a, int b, int year) {
    if (a > 31 || b > 31) {
      return null;
    }
    if (a > 12 && b <= 12) {
      return buildDate(year, b, a);
    }
    if (b > 12 && a <= 12) {
      return buildDate(year, a, b);
    }
    return buildDate(year, b, a);
  }

  static int normalizeYear(int year) {
    if (year >= 100) {
      return year;
    }
    return year >= 50 ? 1900 + year : 2000 + year;
  }

  static DateTime? buildDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    try {
      return DateTime(year, month, day);
    } on ArgumentError {
      return null;
    }
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  List<OcrExtractionResult> mergeResults(
    List<OcrExtractionResult?> candidates,
  ) {
    final results = <OcrExtractionResult>[];
    for (final candidate in candidates) {
      if (candidate != null) {
        results.add(candidate);
      }
    }
    return results;
  }

  /// Regex-only extraction of document numbers and dates without type detection.
  List<OcrExtractionResult> extractNumbersAndDates(String text) {
    final normalized = normalizeText(text);
    final compact = compactText(normalized.toUpperCase());
    final candidates = <OcrExtractionResult?>[
      extractRegexField(
        compact,
        'documentNumber',
        RegExp(r'[A-Z]{2}[0-9]{2}[0-9]{11}'),
        labelKeywords: const ['dl no', 'licence no', 'license no'],
      ),
      extractRegexField(
        compact,
        'documentNumber',
        RegExp(r'[A-Z]{2}[0-9]{13}'),
        labelKeywords: const ['dl no', 'licence no', 'license no'],
      ),
      extractRegexField(
        compact,
        'documentNumber',
        RegExp(r'[A-Z][0-9]{7}'),
        labelKeywords: const ['passport no', 'passport number', 'file no'],
      ),
      extractRegexField(
        compact,
        'documentNumber',
        RegExp(r'[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}'),
        labelKeywords: const ['registration no', 'reg no', 'rc no'],
      ),
      extractRegexField(
        compact,
        'documentNumber',
        RegExp(r'[A-Z]{5}[0-9]{4}[A-Z]{1}'),
        labelKeywords: const ['pan', 'permanent account number'],
      ),
      extractRegexField(
        normalized,
        'documentNumber',
        RegExp(r'[0-9]{4}\s[0-9]{4}\s[0-9]{4}'),
        labelKeywords: const ['aadhaar', 'aadhar', 'uid'],
      ),
      extractRegexField(
        compact,
        'documentNumber',
        RegExp(r'[0-9]{12}'),
        labelKeywords: const ['aadhaar', 'aadhar', 'uid'],
        transform: (raw) {
          if (raw.length != 12) {
            return raw;
          }
          return '${raw.substring(0, 4)} ${raw.substring(4, 8)} ${raw.substring(8)}';
        },
      ),
      extractRegexField(
        compact,
        'documentNumber',
        RegExp(r'[A-Z]{2,4}[-/]?[0-9]{6,12}'),
        labelKeywords: const ['policy', 'insurance', 'certificate'],
      ),
      extractIssueDate(normalized),
      extractExpiryDate(normalized),
    ];

    return _bestResultPerField(candidates);
  }

  /// Label-proximity pass: values on the same line or next line after a label.
  List<OcrExtractionResult> extractLabelProximityFields(String text) {
    final normalized = normalizeText(text);
    final lines = normalized.split('\n');
    final bestByField = <String, OcrExtractionResult>{};

    for (final rule in _labelProximityRules) {
      final extracted = _extractNearLabel(lines, normalized, rule);
      if (extracted == null) {
        continue;
      }
      final existing = bestByField[extracted.fieldName];
      if (existing == null || extracted.confidence > existing.confidence) {
        bestByField[extracted.fieldName] = extracted;
      }
    }

    return bestByField.values.toList();
  }

  static final _labelProximityRules = <_LabelProximityRule>[
    _LabelProximityRule(
      fieldName: 'documentNumber',
      labels: ['dl no', 'licence no', 'license no', 'dl number'],
      valuePattern: RegExp(r'[A-Z]{2}[0-9]{2}[0-9]{11}|[A-Z]{2}[0-9]{13}'),
    ),
    _LabelProximityRule(
      fieldName: 'documentNumber',
      labels: ['passport no', 'passport number', 'file no'],
      valuePattern: RegExp(r'[A-Z][0-9]{7}'),
    ),
    _LabelProximityRule(
      fieldName: 'documentNumber',
      labels: ['registration no', 'registration number', 'reg no', 'rc no'],
      valuePattern: RegExp(r'[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}'),
    ),
    _LabelProximityRule(
      fieldName: 'documentNumber',
      labels: ['pan', 'permanent account number'],
      valuePattern: RegExp(r'[A-Z]{5}[0-9]{4}[A-Z]{1}'),
    ),
    _LabelProximityRule(
      fieldName: 'documentNumber',
      labels: ['aadhaar', 'aadhar', 'uid', 'enrolment no'],
      valuePattern: RegExp(r'[0-9]{4}\s?[0-9]{4}\s?[0-9]{4}|[0-9]{12}'),
    ),
    _LabelProximityRule(
      fieldName: 'documentNumber',
      labels: ['policy no', 'policy number', 'certificate no'],
      valuePattern: RegExp(r'[A-Z0-9][A-Z0-9\-/]{5,}'),
    ),
    _LabelProximityRule(
      fieldName: 'issueDate',
      labels: [
        'issue date',
        'date of issue',
        'issued on',
        'doi',
      ],
      isDate: true,
    ),
    _LabelProximityRule(
      fieldName: 'expiryDate',
      labels: [
        'expiry date',
        'date of expiry',
        'expires on',
        'valid until',
        'valid till',
        'valid upto',
        'valid up to',
        'validity',
        'doe',
      ],
      isDate: true,
    ),
    _LabelProximityRule(
      fieldName: 'authority',
      labels: [
        'licensing authority',
        'issuing authority',
        'issued by',
        'rto',
      ],
      maxValueLength: 60,
    ),
  ];

  OcrExtractionResult? _extractNearLabel(
    List<String> lines,
    String fullText,
    _LabelProximityRule rule,
  ) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();

      for (final label in rule.labels) {
        final labelIndex = lowerLine.indexOf(label.toLowerCase());
        if (labelIndex < 0) {
          continue;
        }

        final sameLineRaw = line.substring(labelIndex + label.length);
        final sameLineValue = _valueFromProximitySegment(
          sameLineRaw,
          rule: rule,
        );
        if (sameLineValue != null) {
          return _buildProximityResult(
            fullText: fullText,
            rule: rule,
            value: sameLineValue,
            line: line,
            label: label,
            labelIndex: labelIndex,
          );
        }

        if (i + 1 < lines.length) {
          final nextLineValue = _valueFromProximitySegment(
            lines[i + 1],
            rule: rule,
          );
          if (nextLineValue != null) {
            return _buildProximityResult(
              fullText: fullText,
              rule: rule,
              value: nextLineValue,
              line: lines[i + 1],
              label: label,
              labelIndex: 0,
            );
          }
        }
      }
    }
    return null;
  }

  String? _valueFromProximitySegment(
    String segment, {
    required _LabelProximityRule rule,
  }) {
    var cleaned = segment.trim().replaceFirst(RegExp(r'^[:\-\.\s]+'), '').trim();
    if (cleaned.isEmpty) {
      return null;
    }

    if (rule.isDate) {
      final slice = cleaned.length > 30 ? cleaned.substring(0, 30) : cleaned;
      final parsed = parseDateFromSegment(slice);
      return parsed != null ? formatDate(parsed) : null;
    }

    final upper = cleaned.toUpperCase();
    if (rule.valuePattern != null) {
      final match = rule.valuePattern!.firstMatch(upper);
      if (match != null) {
        var value = match.group(0)!;
        if (RegExp(r'^[0-9]{12}$').hasMatch(value.replaceAll(' ', ''))) {
          final compact = value.replaceAll(' ', '');
          value =
              '${compact.substring(0, 4)} ${compact.substring(4, 8)} ${compact.substring(8)}';
        }
        return value;
      }
      return null;
    }

    if (rule.maxValueLength != null) {
      final trimmed = cleaned.length > rule.maxValueLength!
          ? cleaned.substring(0, rule.maxValueLength!).trim()
          : cleaned;
      return trimmed.length >= 3 ? trimmed : null;
    }

    return null;
  }

  OcrExtractionResult _buildProximityResult({
    required String fullText,
    required _LabelProximityRule rule,
    required String value,
    required String line,
    required String label,
    required int labelIndex,
  }) {
    final matchStart = fullText.indexOf(line) + labelIndex;
    final matchEnd = matchStart + label.length + value.length;
    final confidence = scoreField(
      text: fullText,
      value: value,
      matchStart: matchStart.clamp(0, fullText.length),
      matchEnd: matchEnd.clamp(0, fullText.length),
      labelKeywords: rule.labels,
      regexMatched: true,
    );
    return OcrExtractionResult(
      fieldName: rule.fieldName,
      extractedValue: value,
      confidence: (confidence + 8).clamp(0, 100),
    );
  }

  List<OcrExtractionResult> _bestResultPerField(
    List<OcrExtractionResult?> candidates,
  ) {
    final bestByField = <String, OcrExtractionResult>{};
    for (final candidate in candidates) {
      if (candidate == null) {
        continue;
      }
      final existing = bestByField[candidate.fieldName];
      if (existing == null || candidate.confidence > existing.confidence) {
        bestByField[candidate.fieldName] = candidate;
      }
    }
    return bestByField.values.toList();
  }
}

class _LabelProximityRule {
  const _LabelProximityRule({
    required this.fieldName,
    required this.labels,
    this.isDate = false,
    this.valuePattern,
    this.maxValueLength,
  });

  final String fieldName;
  final List<String> labels;
  final bool isDate;
  final RegExp? valuePattern;
  final int? maxValueLength;
}

enum DateCategory {
  birthDate,
  issueDate,
  expiryDate,
  unknown;

  String get label {
    switch (this) {
      case DateCategory.birthDate:
        return 'Birth Date';
      case DateCategory.issueDate:
        return 'Issue Date';
      case DateCategory.expiryDate:
        return 'Expiry Date';
      case DateCategory.unknown:
        return 'Unknown';
    }
  }
}

class CategorizedDate {
  const CategorizedDate({
    required this.date,
    required this.formatted,
    required this.start,
    required this.end,
    required this.type,
  });

  final DateTime date;
  final String formatted;
  final int start;
  final int end;
  final DateCategory type;
}
