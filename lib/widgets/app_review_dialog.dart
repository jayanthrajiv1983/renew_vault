import 'package:flutter/material.dart';

import '../services/app_review_service.dart';

enum AppReviewDialogAction { rate, later, noThanks }

/// Shows the "Enjoying Renew Vault?" review prompt.
Future<AppReviewDialogAction?> showAppReviewDialog(BuildContext context) {
  return showDialog<AppReviewDialogAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Enjoying Renew Vault?'),
      content: const Text(
        'If you have a moment, a quick rating helps others discover Renew Vault.',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(AppReviewDialogAction.noThanks),
          child: const Text('No Thanks'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(AppReviewDialogAction.later),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(AppReviewDialogAction.rate),
          child: const Text('Rate App'),
        ),
      ],
    ),
  );
}

/// Records a home launch and presents the review prompt when eligible.
Future<void> maybeShowAppReviewPrompt(BuildContext context) async {
  await AppReviewService.instance.recordHomeLaunch();

  if (!context.mounted) {
    return;
  }

  if (!AppReviewService.instance.shouldShowPrompt) {
    return;
  }

  final action = await showAppReviewDialog(context);
  if (!context.mounted || action == null) {
    return;
  }

  switch (action) {
    case AppReviewDialogAction.rate:
      await AppReviewService.instance.requestReview();
    case AppReviewDialogAction.later:
      await AppReviewService.instance.markLater();
    case AppReviewDialogAction.noThanks:
      await AppReviewService.instance.markPermanentlyDismissed();
  }
}
