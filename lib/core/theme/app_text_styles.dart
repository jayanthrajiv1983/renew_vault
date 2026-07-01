import 'package:flutter/material.dart';

/// Centralized premium typography for Renew Vault.
///
/// Access semantic styles via [AppTextStyles.of]:
/// `AppTextStyles.of(context).sectionTitle(color: colorScheme.onSurface)`.
///
/// ## Information hierarchy (Sprint 23.6)
///
/// **Level 1 — PRIMARY** (scan first): item titles, stat values, days-left /
/// expired status, numeric values. Color: `onSurface` or semantic status.
/// Weight: w600. Tokens: [itemTitle], [daysLeft], [fieldValue],
/// [dashboardNumber], [primaryInfo].
///
/// **Level 2 — SECONDARY** (support, don't compete): category names, field
/// labels, supporting descriptions. Color: `onSurfaceVariant`. Weight: w400–w500.
/// Tokens: [categoryText], [detailFieldLabel], [dashboardTitle],
/// [secondaryInfo].
///
/// **Level 3 — TERTIARY** (unobtrusive): owner chips, helper text, empty
/// states, metadata, attachment hints. Color: `onSurfaceVariant` (softer) or
/// `outline`. Weight: w400, smaller. Tokens: [metadata], [dashboardSubtitle],
/// [tertiaryInfo].
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.displayLarge,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.titleLarge,
    required this.titleMedium,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.labelLarge,
    required this.sectionTitleStyle,
    required this.itemTitleStyle,
    required this.categoryTextStyle,
    required this.metadataStyle,
    required this.daysLeftStyle,
    required this.dashboardNumberStyle,
    required this.dashboardTitleStyle,
    required this.dashboardSubtitleStyle,
    required this.fieldValueStyle,
    required this.detailSectionHeaderStyle,
    required this.detailFieldLabelStyle,
  });

  // ── Material-style named roles ──────────────────────────────────────────

  final TextStyle displayLarge;
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle labelLarge;

  // ── Semantic style bases ──────────────────────────────────────────────────

  final TextStyle sectionTitleStyle;
  final TextStyle itemTitleStyle;
  final TextStyle categoryTextStyle;
  final TextStyle metadataStyle;
  final TextStyle daysLeftStyle;
  final TextStyle dashboardNumberStyle;
  final TextStyle dashboardTitleStyle;
  final TextStyle dashboardSubtitleStyle;
  final TextStyle fieldValueStyle;
  final TextStyle detailSectionHeaderStyle;
  final TextStyle detailFieldLabelStyle;

  /// Resolves [AppTextStyles] from the nearest [Theme].
  static AppTextStyles of(BuildContext context) {
    return Theme.of(context).extension<AppTextStyles>()!;
  }

  /// Builds typography from an Inter-backed [TextTheme] (see [AppTheme]).
  factory AppTextStyles.fromTextTheme(TextTheme textTheme) {
    TextStyle base(TextStyle? style) => style ?? const TextStyle();

    return AppTextStyles(
      displayLarge: base(textTheme.displayLarge),
      headlineLarge: base(textTheme.headlineLarge),
      headlineMedium: base(textTheme.headlineMedium),
      titleLarge: base(textTheme.titleLarge),
      titleMedium: base(textTheme.titleMedium),
      bodyLarge: base(textTheme.bodyLarge),
      bodyMedium: base(textTheme.bodyMedium),
      labelLarge: base(textTheme.labelLarge),
      sectionTitleStyle: base(textTheme.titleLarge).copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.25,
      ),
      itemTitleStyle: base(textTheme.titleMedium).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.25,
      ),
      categoryTextStyle: base(textTheme.bodyMedium).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.3,
      ),
      metadataStyle: base(textTheme.bodySmall).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.3,
      ),
      daysLeftStyle: base(textTheme.bodyLarge).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
      ),
      dashboardNumberStyle: base(textTheme.displaySmall).copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.05,
        letterSpacing: -0.5,
      ),
      dashboardTitleStyle: base(textTheme.labelLarge).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      dashboardSubtitleStyle: base(textTheme.bodySmall).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.2,
      ),
      fieldValueStyle: base(textTheme.titleSmall).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      detailSectionHeaderStyle: base(textTheme.titleLarge).copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.25,
      ),
      detailFieldLabelStyle: base(textTheme.bodyMedium).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.3,
      ),
    );
  }

  // ── Semantic aliases (color-aware) ────────────────────────────────────────

  // Level 1 — PRIMARY

  /// Generic L1 token (16sp w600). Prefer [itemTitle], [fieldValue], etc.
  TextStyle primaryInfo({Color? color}) =>
      itemTitleStyle.copyWith(color: color);

  /// Section titles: 18sp w600, letterSpacing -0.2.
  TextStyle sectionTitle({Color? color}) =>
      sectionTitleStyle.copyWith(color: color);

  /// Renewal / list item titles — L1: 16sp w600, letterSpacing -0.1.
  TextStyle itemTitle({Color? color}) =>
      itemTitleStyle.copyWith(color: color);

  /// Days-left / expired status — L1: 14sp w600.
  TextStyle daysLeft({Color? color}) => daysLeftStyle.copyWith(color: color);

  /// Dashboard stat value — L1: 30sp w600.
  TextStyle dashboardNumber({Color? color}) =>
      dashboardNumberStyle.copyWith(color: color);

  /// Detail field values — L1: 16sp w600 (use onSurface or primary).
  TextStyle fieldValue({Color? color}) =>
      fieldValueStyle.copyWith(color: color);

  /// Detail screen section headers — 18sp w600, letterSpacing -0.2.
  TextStyle detailSectionHeader({Color? color}) =>
      detailSectionHeaderStyle.copyWith(color: color);

  // Level 2 — SECONDARY

  /// Generic L2 token (13sp w400). Prefer [categoryText], [detailFieldLabel].
  TextStyle secondaryInfo({Color? color}) =>
      categoryTextStyle.copyWith(color: color);

  /// Category and secondary labels — L2: 13sp w400 (use onSurfaceVariant).
  TextStyle categoryText({Color? color}) =>
      categoryTextStyle.copyWith(color: color);

  /// Dashboard stat label — L2: 14sp w500.
  TextStyle dashboardTitle({Color? color}) =>
      dashboardTitleStyle.copyWith(color: color);

  /// Detail field labels (Title, Category, etc.) — L2: 13sp w500.
  TextStyle detailFieldLabel({Color? color}) =>
      detailFieldLabelStyle.copyWith(color: color);

  // Level 3 — TERTIARY

  /// Generic L3 token (12sp w400). Prefer [metadata], [dashboardSubtitle].
  TextStyle tertiaryInfo({Color? color}) =>
      metadataStyle.copyWith(color: color);

  /// Owner chips and metadata — L3: 12sp w400.
  TextStyle metadata({Color? color}) => metadataStyle.copyWith(color: color);

  /// Dashboard stat subtitle — L3: 12sp w400.
  TextStyle dashboardSubtitle({Color? color}) =>
      dashboardSubtitleStyle.copyWith(color: color);

  @override
  AppTextStyles copyWith({
    TextStyle? displayLarge,
    TextStyle? headlineLarge,
    TextStyle? headlineMedium,
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? labelLarge,
    TextStyle? sectionTitleStyle,
    TextStyle? itemTitleStyle,
    TextStyle? categoryTextStyle,
    TextStyle? metadataStyle,
    TextStyle? daysLeftStyle,
    TextStyle? dashboardNumberStyle,
    TextStyle? dashboardTitleStyle,
    TextStyle? dashboardSubtitleStyle,
    TextStyle? fieldValueStyle,
    TextStyle? detailSectionHeaderStyle,
    TextStyle? detailFieldLabelStyle,
  }) {
    return AppTextStyles(
      displayLarge: displayLarge ?? this.displayLarge,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      labelLarge: labelLarge ?? this.labelLarge,
      sectionTitleStyle: sectionTitleStyle ?? this.sectionTitleStyle,
      itemTitleStyle: itemTitleStyle ?? this.itemTitleStyle,
      categoryTextStyle: categoryTextStyle ?? this.categoryTextStyle,
      metadataStyle: metadataStyle ?? this.metadataStyle,
      daysLeftStyle: daysLeftStyle ?? this.daysLeftStyle,
      dashboardNumberStyle: dashboardNumberStyle ?? this.dashboardNumberStyle,
      dashboardTitleStyle: dashboardTitleStyle ?? this.dashboardTitleStyle,
      dashboardSubtitleStyle:
          dashboardSubtitleStyle ?? this.dashboardSubtitleStyle,
      fieldValueStyle: fieldValueStyle ?? this.fieldValueStyle,
      detailSectionHeaderStyle:
          detailSectionHeaderStyle ?? this.detailSectionHeaderStyle,
      detailFieldLabelStyle:
          detailFieldLabelStyle ?? this.detailFieldLabelStyle,
    );
  }

  @override
  AppTextStyles lerp(AppTextStyles? other, double t) {
    if (other == null) {
      return this;
    }

    TextStyle lerpStyle(TextStyle a, TextStyle b) =>
        TextStyle.lerp(a, b, t) ?? (t < 0.5 ? a : b);

    return AppTextStyles(
      displayLarge: lerpStyle(displayLarge, other.displayLarge),
      headlineLarge: lerpStyle(headlineLarge, other.headlineLarge),
      headlineMedium: lerpStyle(headlineMedium, other.headlineMedium),
      titleLarge: lerpStyle(titleLarge, other.titleLarge),
      titleMedium: lerpStyle(titleMedium, other.titleMedium),
      bodyLarge: lerpStyle(bodyLarge, other.bodyLarge),
      bodyMedium: lerpStyle(bodyMedium, other.bodyMedium),
      labelLarge: lerpStyle(labelLarge, other.labelLarge),
      sectionTitleStyle: lerpStyle(sectionTitleStyle, other.sectionTitleStyle),
      itemTitleStyle: lerpStyle(itemTitleStyle, other.itemTitleStyle),
      categoryTextStyle:
          lerpStyle(categoryTextStyle, other.categoryTextStyle),
      metadataStyle: lerpStyle(metadataStyle, other.metadataStyle),
      daysLeftStyle: lerpStyle(daysLeftStyle, other.daysLeftStyle),
      dashboardNumberStyle:
          lerpStyle(dashboardNumberStyle, other.dashboardNumberStyle),
      dashboardTitleStyle:
          lerpStyle(dashboardTitleStyle, other.dashboardTitleStyle),
      dashboardSubtitleStyle:
          lerpStyle(dashboardSubtitleStyle, other.dashboardSubtitleStyle),
      fieldValueStyle: lerpStyle(fieldValueStyle, other.fieldValueStyle),
      detailSectionHeaderStyle: lerpStyle(
        detailSectionHeaderStyle,
        other.detailSectionHeaderStyle,
      ),
      detailFieldLabelStyle:
          lerpStyle(detailFieldLabelStyle, other.detailFieldLabelStyle),
    );
  }
}
