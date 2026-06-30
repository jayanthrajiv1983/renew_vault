/// Keyword-based document type detection from OCR text.
enum DocumentType {
  passport,
  drivingLicence,
  vehicleInsurance,
  healthInsurance,
  lifeInsurance,
  travelInsurance,
  rcBook,
  warrantyCard,
  invoice,
  amcContract,
  panCard,
  aadhaarCard,
  unknown;

  String get displayName {
    switch (this) {
      case DocumentType.passport:
        return 'Passport';
      case DocumentType.drivingLicence:
        return 'Driving Licence';
      case DocumentType.vehicleInsurance:
        return 'Vehicle Insurance';
      case DocumentType.healthInsurance:
        return 'Health Insurance';
      case DocumentType.lifeInsurance:
        return 'Life Insurance';
      case DocumentType.travelInsurance:
        return 'Travel Insurance';
      case DocumentType.rcBook:
        return 'RC Book';
      case DocumentType.warrantyCard:
        return 'Warranty Card';
      case DocumentType.invoice:
        return 'Invoice';
      case DocumentType.amcContract:
        return 'AMC Contract';
      case DocumentType.panCard:
        return 'PAN Card';
      case DocumentType.aadhaarCard:
        return 'Aadhaar Card';
      case DocumentType.unknown:
        return 'Unknown';
    }
  }

  /// Maps detected type to renewal form category when supported.
  String? suggestedCategory() {
    switch (this) {
      case DocumentType.passport:
      case DocumentType.drivingLicence:
      case DocumentType.panCard:
      case DocumentType.aadhaarCard:
        return 'Document';
      case DocumentType.vehicleInsurance:
      case DocumentType.rcBook:
        return 'Vehicle Insurance';
      case DocumentType.healthInsurance:
        return 'Health Insurance';
      case DocumentType.lifeInsurance:
        return 'Life Insurance';
      case DocumentType.travelInsurance:
        return 'Travel Insurance';
      case DocumentType.warrantyCard:
      case DocumentType.amcContract:
        return 'Appliance';
      case DocumentType.invoice:
        return 'Other';
      case DocumentType.unknown:
        return null;
    }
  }
}

class DocumentClassificationResult {
  const DocumentClassificationResult({
    required this.type,
    required this.confidence,
  });

  final DocumentType type;
  final double confidence;

  int get confidencePercent => confidence.round().clamp(0, 100);

  String get displayType => type.displayName;
}

/// Scores OCR text against keyword lists to infer document type.
abstract final class DocumentClassifierService {
  DocumentClassifierService._();

  static const _confidenceThreshold = 50.0;

  static const _keywords = <DocumentType, List<String>>{
    DocumentType.passport: [
      'passport',
      'republic of india',
      'nationality',
      'place of birth',
      'place of issue',
      'file no',
      'file number',
      'visa',
      'emigration check',
      'travel document',
      'machine readable',
      'mrz',
      'surname',
      'given name',
      'date of birth',
      'passport no',
      'passport number',
    ],
    DocumentType.drivingLicence: [
      'driving licence',
      'driving license',
      'dl no',
      'dl number',
      'licence no',
      'license no',
      'licence number',
      'license number',
      'licensing authority',
      'learner',
      'lmv',
      'transport',
      'non-transport',
      'valid till',
      'valid upto',
      'date of issue',
      'morth',
      'motor vehicles',
      'rto',
      'form of licence',
    ],
    DocumentType.vehicleInsurance: [
      'vehicle insurance',
      'motor insurance',
      'car insurance',
      'auto insurance',
      'certificate of insurance',
      'insured vehicle',
      'registration no',
      'registration number',
      'policy no',
      'policy number',
      'third party',
      'comprehensive',
      'own damage',
      'idv',
      'insured declared value',
      'premium',
      'insurer',
      'motor policy',
    ],
    DocumentType.healthInsurance: [
      'health insurance',
      'mediclaim',
      'hospital',
      'medical',
      'health policy',
      'medical insurance',
      'cashless',
      'tpa',
      'sum insured',
      'pre-existing',
      'family floater',
      'day care',
      'health cover',
      'policy holder',
      'premium',
      'claim',
      'network hospital',
    ],
    DocumentType.lifeInsurance: [
      'life insurance',
      'nominee',
      'sum assured',
      'life cover',
      'death benefit',
      'term plan',
      'endowment',
      'maturity benefit',
      'life assured',
      'policy holder',
      'lic of india',
      'life policy',
      'premium paying term',
      'rider',
    ],
    DocumentType.travelInsurance: [
      'travel insurance',
      'trip',
      'destination',
      'journey',
      'overseas',
      'baggage',
      'flight',
      'travel dates',
      'emergency medical',
      'travel policy',
      'trip duration',
      'passport no',
      'visa',
      'international travel',
    ],
    DocumentType.rcBook: [
      'rc book',
      'registration certificate',
      'certificate of registration',
      'rto',
      'regn',
      'reg no',
      'registration no',
      'motor vehicle',
      'chassis',
      'chassis no',
      'engine no',
      'engine number',
      'owner name',
      'maker',
      'model',
      'fuel',
      'vehicle class',
      'fitness',
    ],
    DocumentType.warrantyCard: [
      'warranty',
      'warranty card',
      'warranty period',
      'guarantee',
      'valid for',
      'serial number',
      'product warranty',
      'manufacturer',
      'dealer',
      'purchase date',
      'warranty valid',
      'limited warranty',
      'service centre',
      'model no',
    ],
    DocumentType.invoice: [
      'invoice',
      'bill',
      'amount',
      'total',
      'tax',
      'gst',
      'cgst',
      'sgst',
      'igst',
      'payment',
      'due date',
      'invoice no',
      'invoice number',
      'bill no',
      'bill number',
      'subtotal',
      'quantity',
      'rate',
      'taxable value',
      'grand total',
    ],
    DocumentType.amcContract: [
      'amc',
      'annual maintenance',
      'maintenance contract',
      'service contract',
      'preventive maintenance',
      'annual contract',
      'service agreement',
      'maintenance agreement',
      'service period',
      'maintenance period',
      'breakdown',
      'service visits',
      'contract period',
    ],
    DocumentType.panCard: [
      'permanent account number',
      'income tax',
      'pan',
      'income tax department',
      'govt of india',
      'government of india',
      'signature',
      'father name',
      'father\'s name',
      'incorporating pan',
      'pan card',
    ],
    DocumentType.aadhaarCard: [
      'aadhaar',
      'aadhar',
      'uid',
      'unique identification',
      'uidai',
      'enrolment',
      'enrollment',
      'government of india',
      'govt of india',
      'your aadhaar',
      'address',
      'dob',
      'date of birth',
      'vid',
    ],
  };

  /// Classifies [ocrText] using keyword scoring. Returns [DocumentType.unknown]
  /// when confidence is below 50%.
  static DocumentClassificationResult classify(String ocrText) {
    final trimmed = ocrText.trim();
    if (trimmed.isEmpty) {
      return const DocumentClassificationResult(
        type: DocumentType.unknown,
        confidence: 0,
      );
    }

    final lower = trimmed.toLowerCase();
    final scores = <DocumentType, int>{};

    for (final entry in _keywords.entries) {
      var score = 0;
      for (final keyword in entry.value) {
        if (lower.contains(keyword.toLowerCase())) {
          score++;
        }
      }
      if (score > 0) {
        scores[entry.key] = score;
      }
    }

    if (scores.isEmpty) {
      return const DocumentClassificationResult(
        type: DocumentType.unknown,
        confidence: 0,
      );
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = ranked.first;
    final secondBestScore = ranked.length > 1 ? ranked[1].value : 0;
    final keywordCount = _keywords[best.key]!.length;

    final matchDensity =
        (best.value / (keywordCount < 6 ? keywordCount : 6)) * 100;
    final relativeMargin = secondBestScore > 0
        ? ((best.value - secondBestScore) / best.value) * 100
        : 100.0;
    final confidence =
        ((matchDensity * 0.5) + (relativeMargin * 0.5)).clamp(0.0, 100.0);

    if (confidence < _confidenceThreshold || best.value < 2) {
      return DocumentClassificationResult(
        type: DocumentType.unknown,
        confidence: confidence,
      );
    }

    return DocumentClassificationResult(
      type: best.key,
      confidence: confidence,
    );
  }
}
