import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

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
    final colorScheme = theme.colorScheme;
    final shape = borderRadius != null
        ? RoundedRectangleBorder(borderRadius: borderRadius!)
        : theme.cardTheme.shape;

    return Card(
      elevation: elevation ?? theme.cardTheme.elevation,
      surfaceTintColor: surfaceTintColor ?? colorScheme.surfaceTint,
      shape: shape,
      margin: const EdgeInsets.only(bottom: AppSpacing.sectionSpacing),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: AppSpacing.cardInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.fieldLabelGap),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.cardSpacing),
            child,
          ],
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.cardSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          if (trailing != null)
            Row(
              children: [
                trailing!,
                const SizedBox(width: AppSpacing.cardSpacing),
                Expanded(child: Text(value)),
              ],
            )
          else
            Text(value),
        ],
      ),
    );
  }
}
