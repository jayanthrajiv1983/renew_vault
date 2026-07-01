import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';
import '../core/theme/design_system.dart';

/// Consistent section title used across list and settings screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.padding,
  });

  final String title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = AppTextStyles.of(context);

    return Padding(
      padding: padding ??
          const EdgeInsets.only(
            top: AppDesignTokens.sectionGap,
            bottom: AppDesignTokens.titleToFirstCard,
          ),
      child: Text(
        title,
        style: textStyles.sectionTitle(
          color: theme.colorScheme.onSurface,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
