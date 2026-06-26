import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Secondary action style for [FormActionBar].
enum FormActionSecondaryStyle {
  text,
  outlined,
}

/// Persistent bottom action area for forms and dialogs.
///
/// Uses [SafeArea] (bottom only), surface background, and keyboard-aware padding.
class FormActionBar extends StatelessWidget {
  const FormActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.onCancel,
    this.cancelLabel = 'Cancel',
    this.secondaryStyle = FormActionSecondaryStyle.text,
    this.primaryEnabled = true,
    this.primaryChild,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onCancel;
  final String cancelLabel;
  final FormActionSecondaryStyle secondaryStyle;
  final bool primaryEnabled;
  final Widget? primaryChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: theme.colorScheme.surface,
      elevation: AppSpacing.cardElevation,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.cardSpacing,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding + viewInsets,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: primaryEnabled ? onPrimary : null,
                    child: primaryChild ?? Text(primaryLabel),
                  ),
                ),
                if (onCancel != null) ...[
                  const SizedBox(height: AppSpacing.fieldLabelGap),
                  SizedBox(
                    width: double.infinity,
                    child: switch (secondaryStyle) {
                      FormActionSecondaryStyle.text => TextButton(
                          onPressed: onCancel,
                          child: Text(cancelLabel),
                        ),
                      FormActionSecondaryStyle.outlined => OutlinedButton(
                          onPressed: onCancel,
                          child: Text(cancelLabel),
                        ),
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
