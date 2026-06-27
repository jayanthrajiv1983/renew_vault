import 'package:flutter/services.dart';

/// Centralized haptic feedback for Renew Vault user actions.
class AppHaptics {
  AppHaptics._();

  /// Swipe action pane revealed.
  static void onSwipeOpened() {
    HapticFeedback.selectionClick();
  }

  static void onEdit() {
    HapticFeedback.lightImpact();
  }

  static void onDuplicate() {
    HapticFeedback.lightImpact();
  }

  static void onDelete() {
    HapticFeedback.mediumImpact();
  }

  static void onUndo() {
    HapticFeedback.lightImpact();
  }

  static void onDuplicateSuccess() {
    HapticFeedback.lightImpact();
  }

  static void onSuccess() {
    HapticFeedback.lightImpact();
  }

  static void onCelebration() {
    HapticFeedback.mediumImpact();
  }
}
