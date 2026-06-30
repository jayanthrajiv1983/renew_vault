import 'package:flutter/material.dart';

import '../constants/categories.dart';
import '../models/renewal_item.dart';
import '../core/theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'owner_avatar.dart';

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

int getDaysRemaining(DateTime renewalDate) {
  return dateOnly(renewalDate).difference(dateOnly(DateTime.now())).inDays;
}

Color getStatusColor(int daysRemaining, ColorScheme colorScheme) {
  if (daysRemaining < 0) {
    return colorScheme.error;
  }
  return AppColors.statusForDaysRemaining(daysRemaining);
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

Color getStatusBadgeColor(int daysRemaining) {
  switch (getStatusLevel(daysRemaining)) {
    case RenewalStatusLevel.expired:
      return AppColors.statExpired;
    case RenewalStatusLevel.expiringSoon:
      return AppColors.statExpiringSoon;
    case RenewalStatusLevel.safe:
      return AppColors.statSafe;
  }
}

class RenewalCard extends StatelessWidget {
  const RenewalCard({
    super.key,
    required this.item,
    required this.onTap,
    this.bottomMargin = AppSpacing.cardSpacing,
  });

  static const double _leadingIconSize = 48;

  /// Tighter than [AppSpacing.sectionSpacing] between icon and text column.
  static const double _iconContentGap = 12;

  /// Status column width — fits two 14sp lines without scaling text down.
  static const double _statusMaxWidth = 100;

  static const double _contentStatusGap = 8;

  static const EdgeInsets _cardContentPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: AppSpacing.cardPadding,
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
        borderRadius: AppSpacing.cardBorderRadius,
        onTap: onTap,
        child: Padding(
          padding: _cardContentPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _leadingIconSize,
                height: _leadingIconSize,
                child: Icon(
                  categoryIcon(item.category),
                  size: _leadingIconSize,
                  color: categoryColor(item.category, theme.colorScheme),
                ),
              ),
              const SizedBox(width: _iconContentGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: textStyles.itemTitle(
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapTitleSubtitle,
                    Text(
                      item.category,
                      style: textStyles.categoryText(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapCategoryOwner,
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
  static const EdgeInsets _padding =
      EdgeInsets.symmetric(horizontal: 8, vertical: 4);

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
          children: [
            OwnerAvatar(ownerName: ownerName, radius: _avatarRadius),
            const SizedBox(width: AppSpacing.fieldLabelGap),
            Flexible(
              child: Text(
                ownerName,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
