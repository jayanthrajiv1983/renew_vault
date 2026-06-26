import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'aadhaar_parser.dart';
import 'document_parser.dart';
import 'document_type.dart';
import 'driving_license_parser.dart';
import 'insurance_parser.dart';
import 'ocr_extraction_result.dart';
import 'pan_parser.dart';
import 'passport_parser.dart';
import 'vehicle_rc_parser.dart';

class OcrEngineResult {
  const OcrEngineResult({
    required this.rawText,
    required this.documentType,
    required this.fields,
  });

  final String rawText;
  final DocumentType documentType;
  final List<OcrExtractionResult> fields;

  bool get hasAnyFields => fields.isNotEmpty;

  List<OcrExtractionResult> get highConfidenceFields =>
      fields.where((field) => field.isAutoApplicable).toList();

  List<OcrExtractionResult> get lowConfidenceFields =>
      fields.where((field) => !field.isAutoApplicable).toList();

  OcrExtractionResult? fieldNamed(String name) {
    for (final field in fields) {
      if (field.fieldName == name) {
        return field;
      }
    }
    return null;
  }
}

class OcrEngine {
  OcrEngine._();

  static TextRecognizer? _recognizer;

  static TextRecognizer get _textRecognizer {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _recognizer!;
  }

  static const _typeKeywords = <DocumentType, List<String>>{
    DocumentType.drivingLicense: [
      'driving licence',
      'driving license',
      'dl no',
      'licence no',
      'license no',
      'licensing authority',
      'learner',
      'lmv',
    ],
    DocumentType.passport: [
      'passport',
      'republic of india',
      'nationality',
      'place of birth',
      'place of issue',
      'file no',
    ],
    DocumentType.vehicleRc: [
      'registration certificate',
      'certificate of registration',
      'motor vehicle',
      'reg no',
      'registration no',
      'chassis',
      'engine no',
    ],
    DocumentType.insurancePolicy: [
      'insurance',
      'policy',
      'premium',
      'insured',
      'coverage',
      'sum insured',
      'certificate of insurance',
    ],
    DocumentType.panCard: [
      'permanent account number',
      'income tax department',
      'pan',
      'govt of india',
    ],
    DocumentType.aadhaarCard: [
      'aadhaar',
      'aadhar',
      'uidai',
      'unique identification',
      'enrolment',
      'government of india',
    ],
  };

  static final _parsers = <DocumentParser>[
    DrivingLicenseParser(),
    PassportParser(),
    VehicleRcParser(),
    InsuranceParser(),
    PanParser(),
    AadhaarParser(),
  ];

  static final _textHelpers = _GenericDocumentParser();

  /// Single ML Kit pass + single full-document parser pass (fast scan path).
  static Future<OcrEngineResult> fastScanAndParse(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognized = await _textRecognizer.processImage(inputImage);
    return compute(processTextFast, recognized.text);
  }

  /// Runs OCR on [path], then executes three extraction passes and merges results.
  static Future<OcrEngineResult> scanAndParse(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognized = await _textRecognizer.processImage(inputImage);
    return scanAndParseText(recognized.text);
  }

  static Future<OcrEngineResult> processImage(String path) async {
    return scanAndParse(path);
  }

  /// Single full-document parser pass plus focused date extraction on OCR text.
  static OcrEngineResult processTextFast(String text) {
    final normalized = _textHelpers.normalizeText(text);
    final fullPass = _passFullDocument(normalized);
    final dateFields = _passFastDateFields(normalized);
    final mergedFields = _mergeResults([
      fullPass.fields,
      dateFields,
    ]);

    return OcrEngineResult(
      rawText: normalized,
      documentType: fullPass.documentType,
      fields: mergedFields,
    );
  }

  static List<OcrExtractionResult> _passFastDateFields(String text) {
    final candidates = <OcrExtractionResult?>[
      _textHelpers.extractIssueDate(text),
      _textHelpers.extractExpiryDate(text),
    ];

    for (final field in _textHelpers.extractLabelProximityFields(text)) {
      if (field.fieldName == 'issueDate' || field.fieldName == 'expiryDate') {
        candidates.add(field);
      }
    }

    return _bestResultsFromCandidates(candidates);
  }

  static List<OcrExtractionResult> _bestResultsFromCandidates(
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

  /// Multi-pass extraction on already recognized OCR text.
  static OcrEngineResult scanAndParseText(String text) {
    final normalized = _textHelpers.normalizeText(text);

    final fullPass = _passFullDocument(normalized);
    final numbersDates = _passNumbersAndDates(normalized);
    final labelProximity = _passLabelProximity(normalized);

    final mergedFields = _mergeResults([
      fullPass.fields,
      numbersDates,
      labelProximity,
    ]);

    return OcrEngineResult(
      rawText: normalized,
      documentType: fullPass.documentType,
      fields: mergedFields,
    );
  }

  static OcrEngineResult processText(String text) {
    return scanAndParseText(text);
  }

  static OcrEngineResult _passFullDocument(String text) {
    final documentType = detectDocumentType(text);
    final parser = parserFor(documentType);
    return OcrEngineResult(
      rawText: text,
      documentType: documentType,
      fields: parser.parse(text),
    );
  }

  static List<OcrExtractionResult> _passNumbersAndDates(String text) {
    final candidates = <List<OcrExtractionResult>>[
      _textHelpers.extractNumbersAndDates(text),
      _extractNumbersAndDatesFromAllParsers(text),
    ];
    return _mergeResults(candidates);
  }

  static List<OcrExtractionResult> _extractNumbersAndDatesFromAllParsers(
    String text,
  ) {
    const numberDateFields = {'documentNumber', 'issueDate', 'expiryDate'};
    final results = <OcrExtractionResult>[];
    for (final parser in _parsers) {
      for (final field in parser.parse(text)) {
        if (numberDateFields.contains(field.fieldName)) {
          results.add(field);
        }
      }
    }
    return results;
  }

  static List<OcrExtractionResult> _passLabelProximity(String text) {
    return _textHelpers.extractLabelProximityFields(text);
  }

  static List<OcrExtractionResult> _mergeResults(
    List<List<OcrExtractionResult>> passResults,
  ) {
    final bestByField = <String, OcrExtractionResult>{};
    for (final pass in passResults) {
      for (final result in pass) {
        final existing = bestByField[result.fieldName];
        if (existing == null || result.confidence > existing.confidence) {
          bestByField[result.fieldName] = result;
        }
      }
    }
    return bestByField.values.toList();
  }

  static DocumentType detectDocumentType(String text) {
    final scores = <DocumentType, int>{};

    for (final entry in _typeKeywords.entries) {
      final score = DocumentParser.scoreDocumentType(text, entry.value);
      if (score > 0) {
        scores[entry.key] = score;
      }
    }

    _boostScoresFromPatterns(text, scores);

    if (scores.isEmpty) {
      return DocumentType.unknown;
    }

    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static void _boostScoresFromPatterns(
    String text,
    Map<DocumentType, int> scores,
  ) {
    final compact = _textHelpers.compactText(text.toUpperCase());

    if (DrivingLicenseParser().parse(compact).any((f) => f.fieldName == 'documentNumber')) {
      scores[DocumentType.drivingLicense] =
          (scores[DocumentType.drivingLicense] ?? 0) + 2;
    }
    if (PassportParser().parse(compact).any((f) => f.fieldName == 'documentNumber')) {
      scores[DocumentType.passport] = (scores[DocumentType.passport] ?? 0) + 2;
    }
    if (VehicleRcParser().parse(compact).any((f) => f.fieldName == 'documentNumber')) {
      scores[DocumentType.vehicleRc] = (scores[DocumentType.vehicleRc] ?? 0) + 2;
    }
    if (PanParser().parse(compact).any((f) => f.fieldName == 'documentNumber')) {
      scores[DocumentType.panCard] = (scores[DocumentType.panCard] ?? 0) + 2;
    }
    if (AadhaarParser().parse(compact).any((f) => f.fieldName == 'documentNumber')) {
      scores[DocumentType.aadhaarCard] =
          (scores[DocumentType.aadhaarCard] ?? 0) + 2;
    }
    if (InsuranceParser().parse(compact).any((f) => f.fieldName == 'documentNumber')) {
      scores[DocumentType.insurancePolicy] =
          (scores[DocumentType.insurancePolicy] ?? 0) + 2;
    }
  }

  static DocumentParser parserFor(DocumentType type) {
    for (final parser in _parsers) {
      if (parser.documentType == type) {
        return parser;
      }
    }
    return _GenericDocumentParser();
  }

  static void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}

class _GenericDocumentParser extends DocumentParser {
  @override
  DocumentType get documentType => DocumentType.unknown;

  @override
  List<OcrExtractionResult> parse(String text) {
    final results = <OcrExtractionResult>[];
    for (final parser in OcrEngine._parsers) {
      results.addAll(parser.parse(text));
    }

    final bestByField = <String, OcrExtractionResult>{};
    for (final result in results) {
      final existing = bestByField[result.fieldName];
      if (existing == null || result.confidence > existing.confidence) {
        bestByField[result.fieldName] = result;
      }
    }
    return bestByField.values.toList();
  }
}
