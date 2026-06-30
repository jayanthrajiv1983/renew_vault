import 'package:homecare_vault/features/ocr/services/document_classifier_service.dart';
import 'package:homecare_vault/features/ocr/services/document_extractors/driving_licence_extractor.dart';

void main() {
  const sample = '''
UNION OF INDIA
Driving Licence
DL No. KA01 20210012345
Name: TEST USER
Date of Issue: 15/03/2021
Valid Till: 14/03/2031
Valid Throughout India
Licensing Authority: RTO Bangalore
''';

  final classification = DocumentClassifierService.classify(sample);
  final extracted = DrivingLicenceExtractor().extract(sample);

  print('Type: ${classification.displayType} (${classification.confidencePercent}%)');
  print('DL: ${extracted.documentNumber}');
  print('Issue: ${extracted.issueDate}');
  print('Expiry: ${extracted.expiryDate}');
  print('Authority: ${extracted.authority}');
  print('Field count: ${extracted.extractedFieldCount}');
}
