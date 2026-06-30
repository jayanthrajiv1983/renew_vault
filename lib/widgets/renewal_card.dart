import 'package:flutter/material.dart';

import '../constants/categories.dart';
import '../models/renewal_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'owner_avatar.dart';

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

int getDaysRemaining(DateTime renewalDate) {
  return dateOnly(renewalDate).difference(dateOnly(DateTime.now())).inDays;
}

Color getStatusColor(int daysRemaining) {
  return AppColors.statusForDaysRemaining(daysRemaining);
}

String getStatusText(int daysRemaining) {
  if (daysRemaining < 0) {
    final daysAgo = -daysRemaining;
    return daysAgo == 1 ? 'Expired 1 day ago' : 'Expired $daysAgo days ago';
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
  });

  final RenewalItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final daysRemaining = getDaysRemaining(item.renewalDate);
    final statusColor = getStatusColor(daysRemaining);
    final statusText = getStatusText(daysRemaining);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.cardSpacing),
      child: InkWell(
        borderRadius: AppSpacing.cardBorderRadius,
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.cardInsets,
          child: Row(
            children: [
              Icon(
                categoryIcon(item.category),
                size: 40,
                color: categoryColor(item.category, theme.colorScheme),
              ),
              const SizedBox(width: AppSpacing.sectionSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        OwnerAvatar(ownerName: item.owner),
                        const SizedBox(width: AppSpacing.fieldLabelGap),
                        Expanded(
                          child: Text(
                            item.owner,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.cardSpacing),
              Flexible(
                child: Text(
                  statusText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
