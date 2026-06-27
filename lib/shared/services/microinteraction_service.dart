import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../widgets/microinteraction_overlay.dart';
import '../widgets/success_overlay.dart';

/// Root navigator for context-free microinteraction overlays.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Centralized lightweight overlay feedback for success, save, delete, and
/// celebration moments across Renew Vault.
class MicrointeractionService {
  MicrointeractionService._() {
    SuccessOverlayCoordinator.dismissMicrointeractionPeer =
        () => _dismissCurrent(immediate: true);
  }

  static final MicrointeractionService instance = MicrointeractionService._();

  OverlayEntry? _currentEntry;
  bool _isShowing = false;

  void showSuccess([BuildContext? context]) =>
      _show(MicrointeractionType.success, context);

  void showCelebration([BuildContext? context]) =>
      _show(MicrointeractionType.celebration, context);

  void showSaved([BuildContext? context]) =>
      _show(MicrointeractionType.saved, context);

  void showDeleted([BuildContext? context]) =>
      _show(MicrointeractionType.deleted, context);

  void showRestored([BuildContext? context]) =>
      _show(MicrointeractionType.restored, context);

  /// Shows any registered [MicrointeractionType], including custom registrations.
  void show(
    MicrointeractionType type, [
    BuildContext? context,
  ]) =>
      _show(type, context);

  void _show(MicrointeractionType type, [BuildContext? context]) {
    final overlayState = _resolveOverlay(context);
    if (overlayState == null) {
      return;
    }

    SuccessOverlayCoordinator.instance.dismissCurrent();
    if (_isShowing) {
      _dismissCurrent(immediate: true);
    }

    final skipAnimation = _shouldSkipAnimation(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return MicrointeractionOverlay(
          type: type,
          skipAnimation: skipAnimation,
          onDismissed: () {
            if (_currentEntry == entry) {
              entry.remove();
              _currentEntry = null;
              _isShowing = false;
            }
          },
        );
      },
    );

    _currentEntry = entry;
    _isShowing = true;
    overlayState.insert(entry);
  }

  void _dismissCurrent({required bool immediate}) {
    final entry = _currentEntry;
    if (entry == null) {
      _isShowing = false;
      return;
    }

    entry.remove();
    _currentEntry = null;
    _isShowing = false;
  }

  OverlayState? _resolveOverlay(BuildContext? context) {
    final navigatorContext =
        context ?? rootNavigatorKey.currentContext;
    if (navigatorContext != null) {
      return Overlay.maybeOf(navigatorContext, rootOverlay: true);
    }

    return rootNavigatorKey.currentState?.overlay;
  }

  bool _shouldSkipAnimation(BuildContext? context) {
    final resolvedContext = context ?? rootNavigatorKey.currentContext;
    if (resolvedContext == null) {
      return false;
    }

    final mediaQuery = MediaQuery.maybeOf(resolvedContext);
    if (mediaQuery != null && mediaQuery.disableAnimations) {
      return true;
    }

    return SchedulerBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }
}
