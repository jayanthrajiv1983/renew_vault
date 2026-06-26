import 'package:flutter/material.dart';

/// Renew Vault brand identity — colors, name, and tagline.
abstract final class AppBrand {
  static const String name = 'Renew Vault';

  static const String tagline = 'Track everything that expires.';

  static const String description =
      'Securely track renewals, warranties, insurance, documents, taxes, and subscriptions.';

  /// Primary brand blue — Material 3 seed color.
  static const Color primaryBlue = Color(0xFF2563EB);

  /// Success / renewal green.
  static const Color green = Color(0xFF22C55E);

  /// Accent orange — refresh ring, highlights.
  static const Color accentOrange = Color(0xFFF59E0B);

  /// Darker blue for gradients and depth.
  static const Color primaryBlueDark = Color(0xFF1D4ED8);

  static const String logoSvgAsset = 'assets/images/logo/renew_vault_logo.svg';

  static const String logoIconAsset = 'assets/images/logo/renew_vault_icon.png';
}
