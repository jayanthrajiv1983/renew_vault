import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';
import '../core/theme/design_system.dart';

class ItemDetailSection extends StatelessWidget {
  const ItemDetailSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.borderRadius,
    this.elevation,
    this.surfaceTintColor,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final BorderRadius? borderRadius;
  final double? elevation;
  final Color? surfaceTintColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = AppTextStyles.of(context);
    final colorScheme = theme.colorScheme;
    final shape = borderRadius != null
        ? RoundedRectangleBorder(borderRadius: borderRadius!)
        : theme.cardTheme.shape;

    return Card(
      elevation: elevation ?? theme.cardTheme.elevation,
      surfaceTintColor: surfaceTintColor ?? colorScheme.surfaceTint,
      shape: shape,
      margin: const EdgeInsets.only(
        top: AppDesignTokens.sectionTopGap,
        bottom: AppDesignTokens.sectionGap,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: AppDesignTokens.detailCardInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: textStyles.detailSectionHeader(
                      color: colorScheme.onSurface,
                    ),
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppDesignTokens.space8),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: AppDesignTokens.detailSectionTitleGap),
            child,
          ],
        ),
      ),
    );
  }
}

/// Standalone information block: Icon → Label → Value.
///
/// Fixed-width icon column keeps labels and values optically aligned across rows.
class DetailInformationBlock extends StatelessWidget {
  const DetailInformationBlock({
    super.key,
    this.icon,
    this.leading,
    required this.label,
    this.value,
    this.valueWidget,
    this.valueColor,
    this.valueMaxLines,
  }) : assert(value != null || valueWidget != null);

  final IconData? icon;
  final Widget? leading;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color? valueColor;
  final int? valueMaxLines;

  bool get _hasLeading => icon != null || leading != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = AppTextStyles.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDesignTokens.detailRowPaddingVertical,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasLeading) ...[
            _buildLeadingSlot(colorScheme),
            const SizedBox(width: AppDesignTokens.detailIconGap),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppDesignTokens.detailFieldLabelGap,
              children: [
                Text(
                  label,
                  style: textStyles.detailFieldLabel(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                ),
                valueWidget ??
                    Text(
                      value!,
                      style: textStyles.fieldValue(
                        color: valueColor ?? colorScheme.onSurface,
                      ),
                      maxLines: valueMaxLines,
                      overflow: valueMaxLines != null
                          ? TextOverflow.ellipsis
                          : null,
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingSlot(ColorScheme colorScheme) {
    if (leading != null) {
      return SizedBox(
        width: AppDesignTokens.detailIconColumnSize,
        height: AppDesignTokens.detailIconColumnSize,
        child: Center(child: leading),
      );
    }

    return SizedBox(
      width: AppDesignTokens.detailIconColumnSize,
      height: AppDesignTokens.detailIconColumnSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppDesignTokens.space8),
        ),
        child: Center(
          // Material outlined glyphs sit ~1px low in a square slot.
          child: Transform.translate(
            offset: const Offset(0, -1),
            child: Icon(
              icon,
              size: AppDesignTokens.iconMedium,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class ItemDetailField extends StatelessWidget {
  const ItemDetailField({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DetailInformationBlock(
      leading: trailing,
      label: label,
      value: value,
    );
  }
}

/// Whitespace separator between detail field blocks.
class DetailFieldGap extends StatelessWidget {
  const DetailFieldGap({super.key});

  @override
  Widget build(BuildContext context) => AppDesignTokens.gapDetailFieldBlock;
}

/// Very subtle inset divider — use sparingly between major groups only.
///
/// Prefer [DetailFieldGap] between standard field rows; this widget is for
/// rare section breaks where whitespace alone is not enough.
class DetailFieldDivider extends StatelessWidget {
  const DetailFieldDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppDesignTokens.detailDividerInset,
        top: AppDesignTokens.detailFieldBlockGap / 2,
        bottom: AppDesignTokens.detailFieldBlockGap / 2,
      ),
      child: Divider(
        height: AppDesignTokens.detailDividerThickness,
        thickness: AppDesignTokens.detailDividerThickness,
        indent: 0,
        endIndent: 0,
        color: AppDesignTokens.detailDividerColor(colorScheme),
      ),
    );
  }
}
