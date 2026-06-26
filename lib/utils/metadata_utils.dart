import 'package:flutter/material.dart';

const metadataLabels = <String, String>{
  'documentNumber': 'Document Number',
  'issueDate': 'Issue Date',
  'authority': 'Authority',
  'issuingAuthority': 'Authority',
  'expiryDate': 'Expiry Date',
  'registrationNumber': 'Registration Number',
  'pucExpiry': 'PUC Expiry',
  'insuranceExpiry': 'Insurance Expiry',
  'lastServiceDate': 'Last Service Date',
  'brand': 'Brand',
  'purchaseDate': 'Purchase Date',
  'warrantyExpiry': 'Warranty Expiry',
  'amcExpiry': 'AMC Expiry',
  'nextServiceDue': 'Next Service Due',
  'policyNumber': 'Policy Number',
  'policyProvider': 'Policy Provider',
  'coverageAmount': 'Coverage Amount',
  'annualCost': 'Annual Cost',
  'taxType': 'Tax Type',
  'dueDate': 'Due Date',
};

const metadataDateKeys = {
  'issueDate',
  'expiryDate',
  'pucExpiry',
  'insuranceExpiry',
  'lastServiceDate',
  'purchaseDate',
  'warrantyExpiry',
  'amcExpiry',
  'nextServiceDue',
  'dueDate',
};

const categoryMetadataKeys = <String, List<String>>{
  'Document': ['documentNumber', 'issueDate', 'authority'],
  'Vehicle': [
    'registrationNumber',
    'pucExpiry',
    'insuranceExpiry',
    'lastServiceDate',
  ],
  'Appliance': [
    'brand',
    'purchaseDate',
    'warrantyExpiry',
    'amcExpiry',
    'lastServiceDate',
    'nextServiceDue',
  ],
  'Insurance': [
    'policyNumber',
    'policyProvider',
    'coverageAmount',
    'annualCost',
  ],
  'Tax': ['taxType', 'authority', 'dueDate', 'annualCost'],
};

class CategoryMetadataSection {
  const CategoryMetadataSection({
    required this.title,
    required this.keys,
  });

  final String title;
  final List<String> keys;
}

class PopulatedMetadataSection {
  const PopulatedMetadataSection({
    required this.title,
    required this.entries,
  });

  final String title;
  final List<MapEntry<String, dynamic>> entries;
}

const categoryMetadataSections = <String, List<CategoryMetadataSection>>{
  'Document': [
    CategoryMetadataSection(
      title: 'Document Information',
      keys: ['documentNumber', 'issueDate'],
    ),
    CategoryMetadataSection(
      title: 'Issuing Authority',
      keys: ['authority'],
    ),
  ],
  'Vehicle': [
    CategoryMetadataSection(
      title: 'Vehicle Information',
      keys: ['registrationNumber'],
    ),
    CategoryMetadataSection(
      title: 'Compliance',
      keys: ['pucExpiry', 'insuranceExpiry'],
    ),
    CategoryMetadataSection(
      title: 'Maintenance',
      keys: ['lastServiceDate'],
    ),
  ],
  'Appliance': [
    CategoryMetadataSection(
      title: 'Product Information',
      keys: ['brand', 'purchaseDate'],
    ),
    CategoryMetadataSection(
      title: 'Warranty & Coverage',
      keys: ['warrantyExpiry', 'amcExpiry'],
    ),
    CategoryMetadataSection(
      title: 'Maintenance',
      keys: ['lastServiceDate', 'nextServiceDue'],
    ),
  ],
  'Insurance': [
    CategoryMetadataSection(
      title: 'Policy Information',
      keys: ['policyNumber', 'policyProvider'],
    ),
    CategoryMetadataSection(
      title: 'Coverage & Cost',
      keys: ['coverageAmount', 'annualCost'],
    ),
  ],
  'Tax': [
    CategoryMetadataSection(
      title: 'Tax Information',
      keys: ['taxType', 'authority'],
    ),
    CategoryMetadataSection(
      title: 'Payment Schedule',
      keys: ['dueDate', 'annualCost'],
    ),
  ],
};

String metadataLabel(String key) {
  return metadataLabels[key] ??
      key.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)!} ${match.group(2)!}',
      );
}

IconData metadataIcon(String key) {
  return switch (key) {
    'documentNumber' ||
    'registrationNumber' ||
    'policyNumber' =>
      Icons.badge_outlined,
    'issueDate' ||
    'expiryDate' ||
    'pucExpiry' ||
    'insuranceExpiry' ||
    'purchaseDate' ||
    'warrantyExpiry' ||
    'amcExpiry' ||
    'nextServiceDue' ||
    'dueDate' ||
    'lastServiceDate' =>
      Icons.calendar_today_outlined,
    'authority' || 'issuingAuthority' => Icons.business_outlined,
    'licenseClass' => Icons.card_membership_outlined,
    'brand' => Icons.storefront_outlined,
    'policyProvider' => Icons.shield_outlined,
    'coverageAmount' || 'annualCost' => Icons.payments_outlined,
    'taxType' => Icons.receipt_long_outlined,
    _ => Icons.info_outline,
  };
}

String formatMetadataDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String formatMetadataValue(String key, dynamic value) {
  if (value == null) {
    return '';
  }

  if (metadataDateKeys.contains(key)) {
    if (value is String && value.isNotEmpty) {
      try {
        return formatMetadataDate(DateTime.parse(value));
      } catch (_) {
        return value;
      }
    }
    if (value is DateTime) {
      return formatMetadataDate(value);
    }
  }

  return value.toString();
}

Map<String, dynamic> metadataForCategory(
  String category,
  Map<String, dynamic> metadata,
) {
  final keys = categoryMetadataKeys[category];
  if (keys == null) {
    return {};
  }

  final filtered = <String, dynamic>{};
  for (final key in keys) {
    final value = metadata[key];
    if (value == null) {
      continue;
    }
    if (value is String && value.trim().isEmpty) {
      continue;
    }
    filtered[key] = value;
  }
  return filtered;
}

List<PopulatedMetadataSection> metadataSectionsForCategory(
  String category,
  Map<String, dynamic> metadata,
) {
  final sectionDefs = categoryMetadataSections[category];
  if (sectionDefs == null) {
    return [];
  }

  final filtered = metadataForCategory(category, metadata);
  if (filtered.isEmpty) {
    return [];
  }

  final sections = <PopulatedMetadataSection>[];
  final assignedKeys = <String>{};

  for (final section in sectionDefs) {
    final entries = <MapEntry<String, dynamic>>[];
    for (final key in section.keys) {
      final value = filtered[key];
      if (value != null) {
        entries.add(MapEntry(key, value));
        assignedKeys.add(key);
      }
    }
    if (entries.isNotEmpty) {
      sections.add(
        PopulatedMetadataSection(title: section.title, entries: entries),
      );
    }
  }

  final unassigned = filtered.entries
      .where((entry) => !assignedKeys.contains(entry.key))
      .toList();
  if (unassigned.isNotEmpty) {
    sections.add(
      PopulatedMetadataSection(
        title: 'Additional Details',
        entries: unassigned,
      ),
    );
  }

  return sections;
}
