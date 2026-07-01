import 'package:flutter/material.dart';

/// Centralized layout, shape, and elevation tokens for Renew Vault.
///
/// Typography lives in [AppTextStyles]; use these tokens for spacing,
/// radii, icon sizes, card borders, and elevations.
abstract final class AppDesignTokens {
  // ── Spacing scale ─────────────────────────────────────────────────────────

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space18 = 18;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // ── Border radius ─────────────────────────────────────────────────────────

  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 20;
  static const double radiusHero = 24;

  // ── Card elevation ────────────────────────────────────────────────────────

  static const double elevationDashboard = 0;
  static const double elevationCard = 0;
  static const double elevationDialog = 2;
  static const double elevationBottomSheet = 3;

  // ── Card border (subtle outline, not shadow) ──────────────────────────────

  static const double cardBorderWidth = 1;
  static const double cardBorderAlpha = 0.08;

  static Color cardBorderColor(ThemeData theme) =>
      theme.dividerColor.withValues(alpha: cardBorderAlpha);

  static BorderSide cardBorderSide(ThemeData theme) => BorderSide(
        color: cardBorderColor(theme),
        width: cardBorderWidth,
      );

  static Border cardBorder(ThemeData theme) =>
      Border.all(color: cardBorderColor(theme), width: cardBorderWidth);

  // ── Icon sizes ────────────────────────────────────────────────────────────

  static const double iconSmall = 18;
  static const double iconMedium = 22;
  static const double iconLarge = 28;
  static const double iconHero = 36;

  // ── Page padding ──────────────────────────────────────────────────────────

  static const double pagePaddingHorizontal = space16;
  static const double pagePaddingVertical = space16;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pagePaddingHorizontal,
    vertical: pagePaddingVertical,
  );

  static const EdgeInsets pageInsets = EdgeInsets.all(pagePaddingHorizontal);

  // ── Section rhythm ────────────────────────────────────────────────────────

  static const double sectionGap = space16;
  static const double sectionTopGap = space4;
  static const double titleToFirstCard = space8;

  /// Section header title color — onSurface at reduced opacity (Sprint 23.6).
  static const double sectionHeaderTextAlpha = 0.9;

  static Color sectionHeaderTextColor(ColorScheme colorScheme) =>
      colorScheme.onSurface.withValues(alpha: sectionHeaderTextAlpha);
  /// Tight padding within a single icon → label → value block.
  static const double detailRowPaddingVertical = 0;

  /// Label-to-value spacing inside a field block.
  static const double detailFieldLabelGap = 2;

  /// Whitespace between field blocks (replaces row dividers).
  static const double detailFieldBlockGap = 20;

  static const double detailSectionTitleGap = space14;
  static const double detailIconColumnSize = 40;
  static const double detailIconGap = 17;

  /// Renewal card list — fixed leading icon column (48×48 circular slot).
  static const double renewalCardIconColumnSize = 48;

  /// Whitespace between renewal-card icon column and text content.
  static const double renewalCardIconGap = space12;

  /// Renewal card list — fixed trailing status column (two 14sp lines, right-aligned).
  static const double renewalCardStatusColumnWidth = 100;

  static const double detailDividerThickness = 1;

  /// Used only when a divider is explicitly needed between major groups.
  static const double detailDividerOpacity = 0.14;
  static const double cardGap = space12;
  static const double heroToDashboard = space16;

  /// Inset for detail-field dividers (icon column + gap).
  static const double detailDividerInset =
      detailIconColumnSize + detailIconGap;

  static Color detailDividerColor(ColorScheme colorScheme) =>
      colorScheme.outlineVariant.withValues(alpha: detailDividerOpacity);

  // ── Shape helpers ─────────────────────────────────────────────────────────

  static BorderRadius get radiusSmallBorder =>
      BorderRadius.circular(radiusSmall);

  static BorderRadius get radiusMediumBorder =>
      BorderRadius.circular(radiusMedium);

  static BorderRadius get radiusLargeBorder =>
      BorderRadius.circular(radiusLarge);

  static BorderRadius get radiusHeroBorder =>
      BorderRadius.circular(radiusHero);

  // ── Common insets & gaps ──────────────────────────────────────────────────

  static const EdgeInsets cardInsets = EdgeInsets.all(space16);

  /// Detail section cards — balanced padding for premium info panels.
  static const EdgeInsets detailCardInsets = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space8,
  );

  /// ListTile padding inside Cards — matches [cardInsets] horizontal rhythm.
  static const EdgeInsets cardListTilePadding = EdgeInsets.symmetric(
    horizontal: space16,
  );

  static SizedBox get gapSection => const SizedBox(height: sectionGap);

  static SizedBox get gapCard => const SizedBox(height: cardGap);

  static SizedBox get gapTitleToFirstCard =>
      const SizedBox(height: titleToFirstCard);

  static SizedBox get gapDetailFieldBlock =>
      const SizedBox(height: detailFieldBlockGap);
}

/// Alias for [AppDesignTokens].
typedef DesignSystem = AppDesignTokens;
