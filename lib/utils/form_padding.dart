import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme/design_system.dart';
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
    left: AppDesignTokens.pagePaddingHorizontal,
    right: AppDesignTokens.pagePaddingHorizontal,
    top: AppDesignTokens.pagePaddingHorizontal,
    bottom: max(100, viewInsets + safeBottom + AppDesignTokens.pagePaddingHorizontal),
  );
}

/// Inset padding for dialogs on small screens.
EdgeInsets dialogInsetPadding(BuildContext context) {
  final safe = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(
    max(AppDesignTokens.pagePaddingHorizontal, safe.left + AppDesignTokens.space8),
    max(AppDesignTokens.pagePaddingVertical, safe.top + AppDesignTokens.sectionGap),
    max(AppDesignTokens.pagePaddingHorizontal, safe.right + AppDesignTokens.space8),
    max(AppDesignTokens.pagePaddingVertical, safe.bottom + AppDesignTokens.sectionGap),
  );
}

/// Content padding for [AlertDialog] bodies — matches [AppDesignTokens.pageInsets].
const EdgeInsets alertDialogContentPadding = AppDesignTokens.pageInsets;

/// Title padding for [AlertDialog] — aligns title X with page horizontal inset.
const EdgeInsets alertDialogTitlePadding = EdgeInsets.fromLTRB(
  AppDesignTokens.pagePaddingHorizontal,
  AppDesignTokens.pagePaddingHorizontal,
  AppDesignTokens.pagePaddingHorizontal,
  AppDesignTokens.space8,
);

/// Actions row padding for [AlertDialog].
const EdgeInsets alertDialogActionsPadding = EdgeInsets.fromLTRB(
  AppDesignTokens.pagePaddingHorizontal,
  0,
  AppDesignTokens.pagePaddingHorizontal,
  AppDesignTokens.pagePaddingHorizontal,
);
