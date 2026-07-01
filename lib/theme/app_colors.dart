import 'package:flutter/material.dart';

import 'app_brand.dart';

/// Shared semantic status colors for Renew Vault.
///
/// All renewal/status UI should use these tokens — not raw [Colors] or
/// [ColorScheme.error] (reserved for form errors, delete, and OCR failures).
abstract final class AppColors {
  /// Total count numerals — follows the app theme primary (blue seed).
  static Color statTotal(ColorScheme colorScheme) => colorScheme.primary;

  // ── Safe (healthy renewal) — dashboard Safe stat card ─────────────────────

  /// Light theme safe foreground — green accent, dashboard Safe value.
  static const Color safeLight = AppBrand.green;

  /// Dark theme safe foreground — green-300, dashboard Safe subtitle.
  static const Color safeDark = Color(0xFF86EFAC);

  static Color safeColor(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark ? safeDark : safeLight;

  static Color safeColorFromBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? safeDark : safeLight;

  /// Soft safe surface — dashboard Safe card gradient start (light).
  static Color safeContainer(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark
          ? const Color(0xFF1A3D2A)
          : const Color(0xFFDCFCE7);

  /// Foreground on [safeContainer] — dashboard Safe card title tone.
  static Color safeOnContainer(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark
          ? const Color(0xFFBBF7D0)
          : const Color(0xFF166534);

  // ── Expiring soon — dashboard Expiring Soon stat card ────────────────────

  /// Light theme expiring foreground — amber accent, dashboard value.
  static const Color expiringLight = AppBrand.accentOrange;

  /// Dark theme expiring foreground — amber-300, dashboard subtitle.
  static const Color expiringDark = Color(0xFFFCD34D);

  static Color expiringColor(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark ? expiringDark : expiringLight;

  static Color expiringColorFromBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? expiringDark : expiringLight;

  /// Soft expiring surface — dashboard Expiring Soon card gradient start.
  static Color expiringContainer(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark
          ? const Color(0xFF3D2E18)
          : const Color(0xFFFEF3C7);

  /// Foreground on [expiringContainer] — dashboard Expiring Soon title tone.
  static Color expiringOnContainer(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark
          ? const Color(0xFFFDE68A)
          : const Color(0xFF92400E);

  // ── Expired — dashboard Expired stat card ────────────────────────────────

  /// Light theme expired foreground — red-600, dashboard Expired subtitle/value.
  static const Color expiredLight = Color(0xFFDC2626);

  /// Dark theme expired foreground — red-300, dashboard Expired subtitle/value.
  static const Color expiredDark = Color(0xFFFCA5A5);

  static Color expiredColor(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark ? expiredDark : expiredLight;

  static Color expiredColorFromBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? expiredDark : expiredLight;

  /// Soft expired surface — dashboard Expired card gradient.
  static Color expiredContainer(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark
          ? const Color(0xFF3D1F1F)
          : const Color(0xFFFEE2E2);

  /// Foreground on [expiredContainer] — dashboard Expired card title tone.
  static Color expiredOnContainer(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark
          ? const Color(0xFFFECACA)
          : const Color(0xFF991B1B);

  // ── Info — informational status (insights, tips) ───────────────────────

  /// Light theme info foreground — blue-500, dashboard Total subtitle.
  static const Color infoLight = Color(0xFF3B82F6);

  /// Dark theme info foreground — blue-300.
  static const Color infoDark = Color(0xFF93C5FD);

  static Color infoColor(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark ? infoDark : infoLight;

  static Color infoColorFromBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? infoDark : infoLight;

  // ── Warning — caution status (log warnings, review prompts) ──────────────

  /// Light theme warning foreground — amber-600, dashboard Expiring subtitle.
  static const Color warningLight = Color(0xFFD97706);

  /// Dark theme warning foreground — amber-400.
  static const Color warningDark = Color(0xFFFBBF24);

  static Color warningColor(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark ? warningDark : warningLight;

  static Color warningColorFromBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? warningDark : warningLight;

  // ── Neutral — inactive / low-priority status ─────────────────────────────

  /// Light theme neutral foreground — gray-500.
  static const Color neutralLight = Color(0xFF6B7280);

  /// Dark theme neutral foreground — gray-400.
  static const Color neutralDark = Color(0xFF9CA3AF);

  static Color neutralColor(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark ? neutralDark : neutralLight;

  static Color neutralColorFromBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? neutralDark : neutralLight;

  /// Status color for individual renewal items by days remaining.
  static Color statusForDaysRemaining(
    int daysRemaining,
    ColorScheme colorScheme,
  ) {
    if (daysRemaining < 0 || daysRemaining <= 7) {
      return expiredColor(colorScheme);
    }
    if (daysRemaining <= 30) {
      return expiringColor(colorScheme);
    }
    return safeColor(colorScheme);
  }
}

/// Convenience accessors for renewal status colors on [ColorScheme].
extension AppStatusColors on ColorScheme {
  Color get safeColor => AppColors.safeColor(this);

  Color get safeContainer => AppColors.safeContainer(this);

  Color get safeOnContainer => AppColors.safeOnContainer(this);

  Color get expiringColor => AppColors.expiringColor(this);

  Color get expiringContainer => AppColors.expiringContainer(this);

  Color get expiringOnContainer => AppColors.expiringOnContainer(this);

  Color get expiredColor => AppColors.expiredColor(this);

  Color get expiredContainer => AppColors.expiredContainer(this);

  Color get expiredOnContainer => AppColors.expiredOnContainer(this);

  Color get infoColor => AppColors.infoColor(this);

  Color get warningColor => AppColors.warningColor(this);

  Color get neutralColor => AppColors.neutralColor(this);
}

/// Ergonomic status color accessors on [ThemeData] (AppTheme-style usage).
extension AppThemeStatusColors on ThemeData {
  Color get safeColor => colorScheme.safeColor;

  Color get expiringColor => colorScheme.expiringColor;

  Color get expiredColor => colorScheme.expiredColor;

  Color get infoColor => colorScheme.infoColor;

  Color get warningColor => colorScheme.warningColor;

  Color get neutralColor => colorScheme.neutralColor;
}
