import 'package:flutter/material.dart';

/// Centralized premium typography for Renew Vault.
///
/// Access semantic styles via [AppTextStyles.of]:
/// `AppTextStyles.of(context).sectionTitle(color: colorScheme.onSurface)`.
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
        fontWeight: FontWeight.w500,
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
        fontWeight: FontWeight.w700,
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
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
    );
  }

  // ── Semantic aliases (color-aware) ────────────────────────────────────────

  /// Section titles: 18sp w500, letterSpacing -0.2.
  TextStyle sectionTitle({Color? color}) =>
      sectionTitleStyle.copyWith(color: color);

  /// Renewal / list item titles: 16sp w600, letterSpacing -0.1.
  TextStyle itemTitle({Color? color}) =>
      itemTitleStyle.copyWith(color: color);

  /// Category and secondary labels: 13sp w400 (use onSurfaceVariant).
  TextStyle categoryText({Color? color}) =>
      categoryTextStyle.copyWith(color: color);

  /// Owner and metadata: 12sp w400.
  TextStyle metadata({Color? color}) => metadataStyle.copyWith(color: color);

  /// Days-left status: 14sp w600.
  TextStyle daysLeft({Color? color}) => daysLeftStyle.copyWith(color: color);

  /// Dashboard stat value: 30sp w700.
  TextStyle dashboardNumber({Color? color}) =>
      dashboardNumberStyle.copyWith(color: color);

  /// Dashboard stat label: 14sp w500.
  TextStyle dashboardTitle({Color? color}) =>
      dashboardTitleStyle.copyWith(color: color);

  /// Dashboard stat subtitle: 12sp w400.
  TextStyle dashboardSubtitle({Color? color}) =>
      dashboardSubtitleStyle.copyWith(color: color);

  /// Detail field values: 16sp w500.
  TextStyle fieldValue({Color? color}) =>
      fieldValueStyle.copyWith(color: color);

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
    );
  }
}
