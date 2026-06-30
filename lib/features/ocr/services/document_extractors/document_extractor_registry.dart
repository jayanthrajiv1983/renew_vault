import '../document_classifier_service.dart';
import 'document_extractor.dart';
import 'driving_licence_extractor.dart';
import 'insurance_extractor.dart';
import 'invoice_extractor.dart';
import 'passport_extractor.dart';
import 'warranty_extractor.dart';

/// Maps [DocumentType] from classification to a template extractor.
abstract final class DocumentExtractorRegistry {
  DocumentExtractorRegistry._();

  static final _passport = PassportExtractor();
  static final _drivingLicence = DrivingLicenceExtractor();
  static final _insurance = InsuranceExtractor();
  static final _warranty = WarrantyExtractor();
  static final _invoice = InvoiceExtractor();

  /// Returns the template extractor for [type], or null when unsupported.
  static DocumentExtractor? forType(DocumentType type) {
    return switch (type) {
      DocumentType.passport => _passport,
      DocumentType.drivingLicence => _drivingLicence,
      DocumentType.vehicleInsurance ||
      DocumentType.healthInsurance ||
      DocumentType.lifeInsurance ||
      DocumentType.travelInsurance =>
        _insurance,
      DocumentType.warrantyCard => _warranty,
      DocumentType.invoice => _invoice,
      DocumentType.rcBook ||
      DocumentType.amcContract ||
      DocumentType.panCard ||
      DocumentType.aadhaarCard ||
      DocumentType.unknown =>
        null,
    };
  }

  /// Human-readable routing table for diagnostics (metadata only).
  static Map<String, String> routingTable() {
    return {
      DocumentType.passport.name: _passport.name,
      DocumentType.drivingLicence.name: _drivingLicence.name,
      DocumentType.vehicleInsurance.name: _insurance.name,
      DocumentType.healthInsurance.name: _insurance.name,
      DocumentType.lifeInsurance.name: _insurance.name,
      DocumentType.travelInsurance.name: _insurance.name,
      DocumentType.warrantyCard.name: _warranty.name,
      DocumentType.invoice.name: _invoice.name,
    };
  }
}
