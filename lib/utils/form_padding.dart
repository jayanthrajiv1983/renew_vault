import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Scroll padding for long forms — clears keyboard and system nav bar.
EdgeInsets formPadding(BuildContext context) {
  final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
  return EdgeInsets.fromLTRB(
    AppSpacing.screenPadding,
    AppSpacing.screenPadding,
    AppSpacing.screenPadding,
    max(100, viewInsets + AppSpacing.screenPadding),
  );
}

/// Scroll padding for forms with a fixed [FormActionBar] below the scroll view.
EdgeInsets formBodyPadding(BuildContext context) {
  final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
  return EdgeInsets.fromLTRB(
    AppSpacing.screenPadding,
    AppSpacing.screenPadding,
    AppSpacing.screenPadding,
    AppSpacing.screenPadding + viewInsets,
  );
}

/// Scroll padding for list/detail screens — clears system nav bar.
EdgeInsets listScrollPadding(
  BuildContext context, {
  double top = AppSpacing.sectionSpacing,
  double horizontal = AppSpacing.screenPadding,
  bool includeFabClearance = false,
}) {
  final safeBottom = MediaQuery.paddingOf(context).bottom;
  final fabExtra = includeFabClearance ? 80.0 : 0.0;
  return EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    max(32 + fabExtra, safeBottom + AppSpacing.screenPadding + fabExtra),
  );
}

/// Padding for modal bottom sheets — safe area, keyboard, and nav bar.
EdgeInsets bottomSheetPadding(BuildContext context) {
  final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
  final safeBottom = MediaQuery.paddingOf(context).bottom;
  return EdgeInsets.only(
    left: AppSpacing.screenPadding,
    right: AppSpacing.screenPadding,
    top: AppSpacing.fieldLabelGap,
    bottom: max(100, viewInsets + safeBottom + AppSpacing.screenPadding),
  );
}

/// Inset padding for dialogs on small screens.
EdgeInsets dialogInsetPadding(BuildContext context) {
  final safe = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(
    max(AppSpacing.screenPadding, safe.left + AppSpacing.fieldLabelGap),
    max(AppSpacing.screenPadding, safe.top + AppSpacing.sectionSpacing),
    max(AppSpacing.screenPadding, safe.right + AppSpacing.fieldLabelGap),
    max(AppSpacing.screenPadding, safe.bottom + AppSpacing.sectionSpacing),
  );
}
