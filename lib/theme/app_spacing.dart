import 'package:flutter/material.dart';

/// Central spacing and shape tokens for Renew Vault.
abstract final class AppSpacing {
  static const double screenPadding = 24;
  static const double sectionSpacing = 16;
  static const double cardSpacing = 12;
  static const double cardPadding = 16;
  static const double cardRadius = 12;
  static const double cardElevation = 1;
  static const double buttonRadius = 20;
  static const double chipRadius = 8;
  static const double fieldSpacing = 16;
  static const double fieldLabelGap = 8;

  static const EdgeInsets screenInsets =
      EdgeInsets.all(screenPadding);

  static const EdgeInsets cardInsets =
      EdgeInsets.all(cardPadding);

  static BorderRadius get cardBorderRadius =>
      BorderRadius.circular(cardRadius);

  static BorderRadius get buttonBorderRadius =>
      BorderRadius.circular(buttonRadius);

  static SizedBox get gapSection => const SizedBox(height: sectionSpacing);

  static SizedBox get gapCard => const SizedBox(height: cardSpacing);

  static SizedBox get gapField => const SizedBox(height: fieldSpacing);
}
