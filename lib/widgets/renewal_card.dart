import 'package:flutter/material.dart';

import '../constants/categories.dart';
import '../models/renewal_item.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/design_system.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import 'owner_avatar.dart';

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

int getDaysRemaining(DateTime renewalDate) {
  return dateOnly(renewalDate).difference(dateOnly(DateTime.now())).inDays;
}

Color getStatusColor(int daysRemaining, ColorScheme colorScheme) {
  return AppColors.statusForDaysRemaining(daysRemaining, colorScheme);
}

String getStatusText(int daysRemaining) {
  if (daysRemaining < 0) {
    final daysAgo = -daysRemaining;
    return daysAgo == 1 ? 'Expired\n1 day ago' : 'Expired\n$daysAgo days ago';
  }
  if (daysRemaining == 0) {
    return 'Expires today';
  }
  if (daysRemaining == 1) {
    return '1 day left';
  }
  return '$daysRemaining days left';
}

/// Compact badge tier aligned with home-screen status filters.
enum RenewalStatusLevel { safe, expiringSoon, expired }

RenewalStatusLevel getStatusLevel(int daysRemaining) {
  if (daysRemaining < 0) {
    return RenewalStatusLevel.expired;
  }
  if (daysRemaining <= 30) {
    return RenewalStatusLevel.expiringSoon;
  }
  return RenewalStatusLevel.safe;
}

String getStatusBadgeLabel(int daysRemaining) {
  switch (getStatusLevel(daysRemaining)) {
    case RenewalStatusLevel.expired:
      return 'Expired';
    case RenewalStatusLevel.expiringSoon:
      return 'Expiring Soon';
    case RenewalStatusLevel.safe:
      return 'Safe';
  }
}

Color getStatusBadgeColor(int daysRemaining, ColorScheme colorScheme) {
  switch (getStatusLevel(daysRemaining)) {
    case RenewalStatusLevel.expired:
      return AppColors.expiredColor(colorScheme);
    case RenewalStatusLevel.expiringSoon:
      return AppColors.expiringColor(colorScheme);
    case RenewalStatusLevel.safe:
      return AppColors.safeColor(colorScheme);
  }
}

class RenewalCard extends StatelessWidget {
  const RenewalCard({
    super.key,
    required this.item,
    required this.onTap,
    this.bottomMargin = AppDesignTokens.cardGap,
  });

  static const double _leadingSlotSize = 48;
  static const double _leadingIconSize = AppDesignTokens.iconMedium;

  static const double _iconContentGap = AppDesignTokens.space8;

  /// Status column width — fits two 14sp lines without scaling text down.
  static const double _statusMaxWidth = 100;

  static const double _contentStatusGap = AppDesignTokens.space8;

  /// Title → category: legacy 10px + 4px breathing room (design tokens).
  static const double _titleCategoryGap =
      AppDesignTokens.space10 + AppDesignTokens.space4;

  /// Category → owner chip: legacy 12px + 6px separation.
  static const double _categoryOwnerGap = AppDesignTokens.space18;

  /// +2px horizontal/top padding, −2px bottom — redistributed, same vertical envelope.
  static const EdgeInsets _cardContentPadding = EdgeInsets.fromLTRB(
    AppDesignTokens.space18,
    AppDesignTokens.space18,
    AppDesignTokens.space16,
    AppDesignTokens.space14,
  );

  final RenewalItem item;
  final VoidCallback onTap;
  final double bottomMargin;

  @override
  Widget build(BuildContext context) {
    final daysRemaining = getDaysRemaining(item.renewalDate);
    final theme = Theme.of(context);
    final statusColor = getStatusColor(daysRemaining, theme.colorScheme);
    final statusText = getStatusText(daysRemaining);
    final textStyles = AppTextStyles.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: bottomMargin),
      child: InkWell(
        borderRadius: AppDesignTokens.radiusSmallBorder,
        onTap: onTap,
        child: Padding(
          padding: _cardContentPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _leadingSlotSize,
                height: _leadingSlotSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: categoryColor(item.category, theme.colorScheme)
                        .withValues(alpha: 0.08),
                  ),
                  child: Center(
                    child: Icon(
                      categoryIcon(item.category),
                      size: _leadingIconSize,
                      color: categoryColor(item.category, theme.colorScheme)
                          .withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _iconContentGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: textStyles
                                .itemTitle(color: theme.colorScheme.onSurface)
                                .copyWith(letterSpacing: 0.18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: _contentStatusGap),
                        SizedBox(
                          width: _statusMaxWidth,
                          child: Text(
                            statusText,
                            style: textStyles.daysLeft(color: statusColor),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            textAlign: TextAlign.end,
                            textHeightBehavior: const TextHeightBehavior(
                              applyHeightToFirstAscent: false,
                              applyHeightToLastDescent: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _titleCategoryGap),
                    Text(
                      item.category,
                      style: textStyles.categoryText(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: _categoryOwnerGap),
                    _OwnerChip(
                      ownerName: item.owner,
                      textStyle: textStyles.metadata(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact owner pill below category — avatar + name, does not compete with title row.
class _OwnerChip extends StatelessWidget {
  const _OwnerChip({
    required this.ownerName,
    required this.textStyle,
    required this.backgroundColor,
  });

  static const double _avatarRadius = 10;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: AppDesignTokens.space8,
    vertical: AppDesignTokens.detailFieldLabelGap,
  );

  final String ownerName;
  final TextStyle textStyle;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Padding(
        padding: _padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            OwnerAvatar(ownerName: ownerName, radius: _avatarRadius),
            const SizedBox(width: AppSpacing.fieldLabelGap),
            Flexible(
              child: Text(
                ownerName,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
