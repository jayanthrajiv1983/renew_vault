import 'package:flutter/material.dart';

/// Renew Vault brand identity — colors, name, and tagline.
abstract final class AppBrand {
  static const String name = 'Renew Vault';

  /// User-facing app name including trademark — use in splash, About, and branding.
  static const String displayName = 'Renew Vault™';

  static const String tagline = 'Your life, organized.';

  /// When true, About and diagnostics show a Beta release-channel badge.
  static const bool isBeta = true;

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

  /// Official logo mark — single source of truth for in-app and launcher art.
  static const String logoAsset = 'assets/images/logo/renew_vault_logo.png';

  /// Alias kept for launcher-icon tooling (same PNG as [logoAsset]).
  static const String logoIconAsset = 'assets/images/logo/renew_vault_icon.png';

  /// Splash composite: logo + app name + tagline (reference / tooling only).
  static const String splashLightAsset =
      'assets/images/logo/renew_vault_splash_light.png';

  /// Splash composite: logo + app name + tagline (reference / tooling only).
  static const String splashDarkAsset =
      'assets/images/logo/renew_vault_splash_dark.png';
}
