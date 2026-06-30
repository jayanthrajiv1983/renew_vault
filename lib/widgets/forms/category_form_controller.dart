import 'package:flutter/material.dart';

import '../../constants/categories.dart';
import '../../models/renewal_item.dart';
import '../../services/ocr_correction_service.dart';
import 'category_detail_keys.dart';

class CategoryFormController {
  CategoryFormController();

  // Appliance
  final brandController = TextEditingController();
  DateTime? purchaseDate;
  DateTime? warrantyExpiry;
  DateTime? amcExpiry;
  DateTime? applianceLastServiceDate;
  DateTime? nextServiceDue;

  // Document
  final documentNumberController = TextEditingController();
  DateTime? issueDate;
  DateTime? expiryDate;
  final authorityController = TextEditingController();

  // Vehicle
  final registrationNumberController = TextEditingController();
  DateTime? insuranceExpiry;
  DateTime? pucExpiry;
  DateTime? vehicleLastServiceDate;

  // Insurance
  final policyNumberController = TextEditingController();
  final policyProviderController = TextEditingController();
  final coverageAmountController = TextEditingController();
  final annualCostController = TextEditingController();
  DateTime? policyExpiry;

  // Tax
  final taxTypeController = TextEditingController();
  final taxAnnualCostController = TextEditingController();
  DateTime? dueDate;

  // Other / generic renewal
  DateTime? renewalDate;

  /// OCR-applied values keyed by field name (Document scan learning).
  final Map<String, String> ocrAppliedValues = {};
  String? ocrDocumentType;

  void clearOcrTracking() {
    ocrAppliedValues.clear();
    ocrDocumentType = null;
  }

  void trackOcrApplied(String fieldName, String ocrValue) {
    ocrAppliedValues[fieldName] = ocrValue;
  }

  String? currentFieldValue(String fieldName) {
    switch (fieldName) {
      case 'documentNumber':
        return documentNumberController.text.trim();
      case 'issueDate':
        return _formatOcrDate(issueDate);
      case 'expiryDate':
        return _formatOcrDate(expiryDate);
      case 'authority':
        return authorityController.text.trim();
      default:
        return null;
    }
  }

  static String? _formatOcrDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> recordOcrCorrectionIfChanged(String fieldName) async {
    final original = ocrAppliedValues[fieldName];
    if (original == null) {
      return;
    }
    final current = currentFieldValue(fieldName);
    if (current == null || current == original) {
      return;
    }
    await OcrCorrectionService.instance.recordCorrection(
      fieldName,
      original,
      current,
      documentType: ocrDocumentType,
    );
    ocrAppliedValues.remove(fieldName);
  }

  Future<void> recordAllPendingOcrCorrections() async {
    for (final fieldName in ocrAppliedValues.keys.toList()) {
      await recordOcrCorrectionIfChanged(fieldName);
    }
  }

  void loadFromItem(RenewalItem item) {
    final details = item.metadata.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );

    brandController.text = details[CategoryDetailKeys.brand] ?? '';
    purchaseDate = parseCategoryDate(details[CategoryDetailKeys.purchaseDate]);
    warrantyExpiry =
        parseCategoryDate(details[CategoryDetailKeys.warrantyExpiry]);
    amcExpiry = parseCategoryDate(details[CategoryDetailKeys.amcExpiry]);
    applianceLastServiceDate =
        parseCategoryDate(details[CategoryDetailKeys.lastServiceDate]);
    nextServiceDue =
        parseCategoryDate(details[CategoryDetailKeys.nextServiceDue]);

    documentNumberController.text =
        details[CategoryDetailKeys.documentNumber] ?? '';
    issueDate = parseCategoryDate(details[CategoryDetailKeys.issueDate]);
    expiryDate = parseCategoryDate(details[CategoryDetailKeys.expiryDate]) ??
        item.renewalDate;
    authorityController.text = details[CategoryDetailKeys.authority] ??
        details['issuingAuthority'] ??
        '';

    registrationNumberController.text =
        details[CategoryDetailKeys.registrationNumber] ?? '';
    insuranceExpiry =
        parseCategoryDate(details[CategoryDetailKeys.insuranceExpiry]);
    pucExpiry = parseCategoryDate(details[CategoryDetailKeys.pucExpiry]);
    vehicleLastServiceDate =
        parseCategoryDate(details[CategoryDetailKeys.lastServiceDate]);

    policyNumberController.text =
        details[CategoryDetailKeys.policyNumber] ?? '';
    policyProviderController.text =
        details[CategoryDetailKeys.policyProvider] ?? '';
    coverageAmountController.text =
        details[CategoryDetailKeys.coverageAmount] ?? '';
    annualCostController.text = details[CategoryDetailKeys.annualCost] ?? '';
    policyExpiry = item.renewalDate;

    taxTypeController.text = details[CategoryDetailKeys.taxType] ?? '';
    taxAnnualCostController.text =
        details[CategoryDetailKeys.annualCost] ?? '';
    authorityController.text = details[CategoryDetailKeys.authority] ?? '';
    dueDate = parseCategoryDate(details[CategoryDetailKeys.dueDate]) ??
        item.renewalDate;

    renewalDate = item.renewalDate;
  }

  void clearCategoryFields() {
    brandController.clear();
    purchaseDate = null;
    warrantyExpiry = null;
    amcExpiry = null;
    applianceLastServiceDate = null;
    nextServiceDue = null;

    documentNumberController.clear();
    issueDate = null;
    expiryDate = null;
    authorityController.clear();
    clearOcrTracking();

    registrationNumberController.clear();
    insuranceExpiry = null;
    pucExpiry = null;
    vehicleLastServiceDate = null;

    policyNumberController.clear();
    policyProviderController.clear();
    coverageAmountController.clear();
    annualCostController.clear();
    policyExpiry = null;

    taxTypeController.clear();
    taxAnnualCostController.clear();
    dueDate = null;

    renewalDate = null;
  }

  DateTime? primaryRenewalDateFor(String category) {
    switch (category) {
      case 'Document':
        return expiryDate;
      case 'Tax':
        return dueDate;
      default:
        if (Categories.isInsuranceCategory(category)) {
          return policyExpiry;
        }
        return renewalDate;
    }
  }

  String? validatePrimaryDate(String category) {
    if (primaryRenewalDateFor(category) == null) {
      switch (category) {
        case 'Document':
          return 'Please select an expiry date';
        case 'Tax':
          return 'Please select a due date';
        default:
          if (Categories.isInsuranceCategory(category)) {
            return 'Please select a policy expiry date';
          }
          return 'Please select a date';
      }
    }
    return null;
  }

  Map<String, dynamic> buildMetadata(String category) {
    final details = <String, dynamic>{};

    void addText(String key, TextEditingController controller) {
      final value = controller.text.trim();
      if (value.isNotEmpty) {
        details[key] = value;
      }
    }

    void addDate(String key, DateTime? date) {
      final formatted = formatCategoryDate(date);
      if (formatted != null) {
        details[key] = formatted;
      }
    }

    switch (category) {
      case 'Appliance':
        addText(CategoryDetailKeys.brand, brandController);
        addDate(CategoryDetailKeys.purchaseDate, purchaseDate);
        addDate(CategoryDetailKeys.warrantyExpiry, warrantyExpiry);
        addDate(CategoryDetailKeys.amcExpiry, amcExpiry);
        addDate(CategoryDetailKeys.lastServiceDate, applianceLastServiceDate);
        addDate(CategoryDetailKeys.nextServiceDue, nextServiceDue);
      case 'Document':
        addText(CategoryDetailKeys.documentNumber, documentNumberController);
        addDate(CategoryDetailKeys.issueDate, issueDate);
        addText(CategoryDetailKeys.authority, authorityController);
      case 'Vehicle Insurance':
        addText(
          CategoryDetailKeys.registrationNumber,
          registrationNumberController,
        );
        addDate(CategoryDetailKeys.insuranceExpiry, insuranceExpiry);
        addDate(CategoryDetailKeys.pucExpiry, pucExpiry);
        addDate(CategoryDetailKeys.lastServiceDate, vehicleLastServiceDate);
      case 'Health Insurance':
      case 'Life Insurance':
      case 'Travel Insurance':
        addText(CategoryDetailKeys.policyNumber, policyNumberController);
        addText(CategoryDetailKeys.policyProvider, policyProviderController);
        addText(CategoryDetailKeys.coverageAmount, coverageAmountController);
        addText(CategoryDetailKeys.annualCost, annualCostController);
      case 'Tax':
        addText(CategoryDetailKeys.taxType, taxTypeController);
        addText(CategoryDetailKeys.authority, authorityController);
        addText(CategoryDetailKeys.annualCost, taxAnnualCostController);
        addDate(CategoryDetailKeys.dueDate, dueDate);
      case 'Other':
      case 'Subscription':
    }

    return details;
  }

  void dispose() {
    brandController.dispose();
    documentNumberController.dispose();
    authorityController.dispose();
    registrationNumberController.dispose();
    policyNumberController.dispose();
    policyProviderController.dispose();
    coverageAmountController.dispose();
    annualCostController.dispose();
    taxTypeController.dispose();
    taxAnnualCostController.dispose();
  }
}
