import 'package:flutter/material.dart';

import '../core/theme/design_system.dart';

/// Spacing and shape aliases for Renew Vault.
///
/// Prefer [AppDesignTokens] for new code. This class maps legacy names to the
/// centralized design system without duplicating values.
abstract final class AppSpacing {
  static const double screenPadding = AppDesignTokens.pagePaddingHorizontal;
  static const double sectionSpacing = AppDesignTokens.sectionGap;
  static const double cardSpacing = AppDesignTokens.cardGap;
  static const double titleSubtitleGap = 10;
  static const double categoryOwnerGap = AppDesignTokens.space12;
  static const double cardPadding = AppDesignTokens.space16;
  static const double cardRadius = AppDesignTokens.radiusSmall;
  static const double cardElevation = AppDesignTokens.elevationCard;
  static const double buttonRadius = AppDesignTokens.radiusLarge;
  static const double chipRadius = AppDesignTokens.space8;
  static const double fieldSpacing = AppDesignTokens.space16;
  static const double fieldLabelGap = AppDesignTokens.space8;

  static const EdgeInsets screenInsets = AppDesignTokens.pageInsets;

  static const EdgeInsets cardInsets = AppDesignTokens.cardInsets;

  static BorderRadius get cardBorderRadius => AppDesignTokens.radiusSmallBorder;

  static BorderRadius get buttonBorderRadius => AppDesignTokens.radiusLargeBorder;

  static SizedBox get gapSection => AppDesignTokens.gapSection;

  static SizedBox get gapCard => AppDesignTokens.gapCard;

  static SizedBox get gapTitleSubtitle =>
      const SizedBox(height: titleSubtitleGap);

  static SizedBox get gapCategoryOwner =>
      const SizedBox(height: categoryOwnerGap);

  static SizedBox get gapField => const SizedBox(height: fieldSpacing);
}
