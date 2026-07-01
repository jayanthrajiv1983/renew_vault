import 'package:flutter/material.dart';

import '../core/theme/design_system.dart';
import '../theme/app_spacing.dart';

class BackupReminderBanner extends StatelessWidget {
  const BackupReminderBanner({
    super.key,
    required this.message,
    required this.onBackupNow,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback? onBackupNow;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.fieldLabelGap),
      child: Material(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: AppSpacing.cardBorderRadius,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.space16,
            vertical: AppDesignTokens.cardGap,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: AppDesignTokens.iconMedium,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.cardSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: onBackupNow,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: theme.colorScheme.onSecondaryContainer,
                      ),
                      child: const Text('Backup Now'),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Dismiss',
                color: theme.colorScheme.onSecondaryContainer,
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
