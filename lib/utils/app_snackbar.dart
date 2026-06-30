import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Consistent in-app snackbars (duration, floating behavior, shape).
abstract final class AppSnackBar {
  static const Duration duration = Duration(seconds: 4);

  static void show(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
  }) {
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? AppSnackBar.duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardBorderRadius,
        ),
        action: action,
      ),
    );
  }
}
