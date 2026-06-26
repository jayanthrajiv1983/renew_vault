import 'package:flutter/material.dart';

/// Shared category icons and colors used across cards, detail views, and charts.
///
/// Color order matches [ordered] and the analytics pie chart palette.
abstract final class Categories {
  static const ordered = [
    'Document',
    'Insurance',
    'Appliance',
    'Vehicle',
    'Tax',
    'Other',
  ];

  static IconData iconFor(String category) {
    switch (category) {
      case 'Vehicle':
        return Icons.directions_car;
      case 'Document':
        return Icons.description;
      case 'Insurance':
        return Icons.security;
      case 'Appliance':
        return Icons.home_repair_service;
      case 'Tax':
        return Icons.account_balance;
      case 'Other':
        return Icons.event_note;
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
    ];
  }
}

IconData categoryIcon(String category) => Categories.iconFor(category);

Color categoryColor(String category, ColorScheme scheme) =>
    Categories.colorFor(category, scheme);
