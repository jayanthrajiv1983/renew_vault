import 'package:flutter/material.dart';

/// Shared category icons and colors used across cards, detail views, and charts.
///
/// Color order matches [ordered] and the analytics pie chart palette.
abstract final class Categories {
  static const ordered = [
    'Appliance',
    'Document',
    'Health Insurance',
    'Life Insurance',
    'Other',
    'Subscription',
    'Tax',
    'Travel Insurance',
    'Vehicle Insurance',
  ];

  static const insuranceCategories = [
    'Health Insurance',
    'Life Insurance',
    'Travel Insurance',
  ];

  static const legacyCategoryReplacements = <String, String>{
    'Vehicle': 'Vehicle Insurance',
    'Insurance': 'Health Insurance',
  };

  static String? legacyReplacementFor(String category) {
    return legacyCategoryReplacements[category];
  }

  static bool isInsuranceCategory(String category) {
    return insuranceCategories.contains(category);
  }

  static IconData iconFor(String category) {
    switch (category) {
      case 'Vehicle Insurance':
        return Icons.directions_car;
      case 'Document':
        return Icons.description;
      case 'Health Insurance':
        return Icons.security;
      case 'Appliance':
        return Icons.home_repair_service;
      case 'Tax':
        return Icons.account_balance;
      case 'Other':
        return Icons.event_note;
      case 'Life Insurance':
        return Icons.favorite_rounded;
      case 'Travel Insurance':
        return Icons.flight_takeoff_rounded;
      case 'Subscription':
        return Icons.subscriptions_outlined;
      default:
        return Icons.event_note;
    }
  }

  static Color colorFor(String category, ColorScheme scheme) {
    final index = ordered.indexOf(category);
    final palette = _palette(scheme);
    if (index < 0) {
      return palette[ordered.indexOf('Other')];
    }
    return palette[index];
  }

  static List<Color> palette(ColorScheme scheme) => _palette(scheme);

  static List<Color> _palette(ColorScheme scheme) {
    return [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.primaryContainer,
      scheme.secondaryContainer,
      scheme.tertiaryContainer,
      scheme.outline,
      scheme.error,
      scheme.inversePrimary,
    ];
  }
}

IconData categoryIcon(String category) => Categories.iconFor(category);

Color categoryColor(String category, ColorScheme scheme) =>
    Categories.colorFor(category, scheme);
