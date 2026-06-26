class CategoryDetailKeys {
  CategoryDetailKeys._();

  // Appliance
  static const brand = 'brand';
  static const purchaseDate = 'purchaseDate';
  static const warrantyExpiry = 'warrantyExpiry';
  static const amcExpiry = 'amcExpiry';
  static const lastServiceDate = 'lastServiceDate';
  static const nextServiceDue = 'nextServiceDue';

  // Document
  static const documentNumber = 'documentNumber';
  static const issueDate = 'issueDate';
  static const expiryDate = 'expiryDate';
  static const authority = 'authority';

  // Vehicle
  static const registrationNumber = 'registrationNumber';
  static const insuranceExpiry = 'insuranceExpiry';
  static const pucExpiry = 'pucExpiry';

  // Insurance
  static const policyNumber = 'policyNumber';
  static const policyProvider = 'policyProvider';
  static const coverageAmount = 'coverageAmount';
  static const annualCost = 'annualCost';

  // Tax
  static const taxType = 'taxType';
  static const dueDate = 'dueDate';
}

String? formatCategoryDate(DateTime? date) {
  if (date == null) {
    return null;
  }
  return DateTime(date.year, date.month, date.day).toIso8601String();
}

DateTime? parseCategoryDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

String formatDisplayDate(DateTime date) {
  return '${date.month}/${date.day}/${date.year}';
}
