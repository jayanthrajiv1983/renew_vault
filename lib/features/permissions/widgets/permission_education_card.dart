import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../models/permission_education_content.dart';

class PermissionEducationCard extends StatelessWidget {
  const PermissionEducationCard({
    super.key,
    required this.content,
    required this.onContinue,
    required this.onNotNow,
  });

  final PermissionEducationContent content;
  final VoidCallback onContinue;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      borderRadius: AppSpacing.cardBorderRadius,
      color: colorScheme.surfaceContainerLow,
      elevation: AppSpacing.cardElevation,
      child: Padding(
        padding: AppSpacing.cardInsets,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _PermissionIcon(
                icon: content.icon,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),
            Text(
              content.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.fieldLabelGap),
            Text(
              content.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.screenPadding),
            FilledButton(
              onPressed: onContinue,
              child: const Text('Continue'),
            ),
            const SizedBox(height: AppSpacing.fieldLabelGap),
            TextButton(
              onPressed: onNotNow,
              child: const Text('Not Now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionIcon extends StatelessWidget {
  const _PermissionIcon({
    required this.icon,
    required this.colorScheme,
  });

  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primary.withValues(alpha: 0.18),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 44,
        color: colorScheme.primary,
      ),
    );
  }
}
