import 'package:flutter/material.dart';

import 'app_brand.dart';

/// Shared semantic colors for dashboard stat numerals and renewal status.
abstract final class AppColors {
  /// Total count numerals — follows the app theme primary (blue seed).
  static Color statTotal(ColorScheme colorScheme) => colorScheme.primary;

  /// Expired count numerals and urgent renewal status.
  static const Color statExpired = Colors.red;

  /// Expiring-soon count numerals and approaching renewal status.
  static const Color statExpiringSoon = AppBrand.accentOrange;

  /// Safe count numerals and healthy renewal status.
  static const Color statSafe = AppBrand.green;

  /// Status color for individual renewal items by days remaining.
  static Color statusForDaysRemaining(int daysRemaining) {
    if (daysRemaining < 0 || daysRemaining <= 7) {
      return statExpired;
    }
    if (daysRemaining <= 30) {
      return statExpiringSoon;
    }
    return statSafe;
  }
}
