import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/haptic_feedback.dart';
import 'success_overlay.dart';

/// Built-in microinteraction categories. Extend via [MicrointeractionRegistry.register].
enum MicrointeractionType {
  success,
  celebration,
  saved,
  deleted,
  restored,
}

enum MicrointeractionEmphasis { standard, celebration }

/// Visual and timing configuration for a [MicrointeractionType].
class MicrointeractionDefinition {
  const MicrointeractionDefinition({
    required this.icon,
    required this.semanticLabel,
    this.iconColor,
    this.haptic,
    this.emphasis = MicrointeractionEmphasis.standard,
    this.holdDuration,
  });

  final IconData icon;
  final String semanticLabel;
  final Color Function(ColorScheme colorScheme)? iconColor;
  final VoidCallback? haptic;
  final MicrointeractionEmphasis emphasis;
  final Duration? holdDuration;

  Duration resolveHoldDuration() {
    if (holdDuration != null) {
      return holdDuration!;
    }
    return emphasis == MicrointeractionEmphasis.celebration
        ? SuccessOverlay.celebrationHoldDuration
        : SuccessOverlay.standardHoldDuration;
  }
}

/// Registry of microinteraction definitions. Override or add types at runtime.
abstract final class MicrointeractionRegistry {
  static final Map<MicrointeractionType, MicrointeractionDefinition> _definitions =
      {
    MicrointeractionType.success: MicrointeractionDefinition(
      icon: Icons.check_circle_rounded,
      semanticLabel: 'Success',
      iconColor: (scheme) => scheme.safeColor,
      haptic: AppHaptics.onSuccess,
    ),
    MicrointeractionType.celebration: MicrointeractionDefinition(
      icon: Icons.celebration_rounded,
      semanticLabel: 'Celebration',
      iconColor: (colorScheme) => colorScheme.expiringColor,
      haptic: AppHaptics.onCelebration,
      emphasis: MicrointeractionEmphasis.celebration,
    ),
    MicrointeractionType.saved: MicrointeractionDefinition(
      icon: Icons.save_rounded,
      semanticLabel: 'Saved',
      iconColor: (colorScheme) => colorScheme.primary,
      haptic: AppHaptics.onSuccess,
    ),
    MicrointeractionType.deleted: MicrointeractionDefinition(
      icon: Icons.delete_outline_rounded,
      semanticLabel: 'Deleted',
      iconColor: (colorScheme) => colorScheme.onSurfaceVariant,
    ),
    MicrointeractionType.restored: MicrointeractionDefinition(
      icon: Icons.restore_rounded,
      semanticLabel: 'Restored',
      iconColor: (colorScheme) => colorScheme.primary,
      haptic: AppHaptics.onSuccess,
    ),
  };

  static MicrointeractionDefinition definitionFor(MicrointeractionType type) {
    return _definitions[type]!;
  }

  static void register(
    MicrointeractionType type,
    MicrointeractionDefinition definition,
  ) {
    _definitions[type] = definition;
  }
}

/// Lightweight toast-style overlay chip for a single microinteraction.
class MicrointeractionOverlay extends StatefulWidget {
  const MicrointeractionOverlay({
    super.key,
    required this.type,
    required this.onDismissed,
    this.skipAnimation = false,
  });

  final MicrointeractionType type;
  final VoidCallback onDismissed;
  final bool skipAnimation;

  @override
  State<MicrointeractionOverlay> createState() =>
      _MicrointeractionOverlayState();
}

class _MicrointeractionOverlayState extends State<MicrointeractionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeScale;
  late final MicrointeractionDefinition _definition;
  bool _isExiting = false;

  Duration get _holdDuration => _definition.resolveHoldDuration();

  Duration get _reducedMotionHoldDuration =>
      _holdDuration +
      SuccessOverlay.enterDuration +
      SuccessOverlay.exitDuration;

  @override
  void initState() {
    super.initState();
    _definition = MicrointeractionRegistry.definitionFor(widget.type);
    _controller = AnimationController(vsync: this);
    _fadeScale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _definition.haptic?.call();
    unawaited(_runSequence());
  }

  Future<void> _runSequence() async {
    if (widget.skipAnimation) {
      _controller.value = 1.0;
      await Future<void>.delayed(_reducedMotionHoldDuration);
      if (!mounted || _isExiting) {
        return;
      }
      await _exit();
      return;
    }

    _controller.duration = SuccessOverlay.enterDuration;
    await _controller.forward();
    if (!mounted || _isExiting) {
      return;
    }

    await Future<void>.delayed(_holdDuration);
    if (!mounted || _isExiting) {
      return;
    }
    await _exit();
  }

  Future<void> _exit() async {
    if (_isExiting) {
      return;
    }
    _isExiting = true;

    if (widget.skipAnimation) {
      widget.onDismissed();
      return;
    }

    _controller.duration = SuccessOverlay.exitDuration;
    await _controller.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor =
        _definition.iconColor?.call(colorScheme) ?? colorScheme.primary;
    final iconSize =
        _definition.emphasis == MicrointeractionEmphasis.celebration ? 30.0 : 26.0;

    final chip = Semantics(
      liveRegion: true,
      label: _definition.semanticLabel,
      child: Material(
        elevation: AppSpacing.cardElevation + 3,
        color: colorScheme.surfaceContainerHighest,
        surfaceTintColor: colorScheme.surfaceTint,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.fieldLabelGap + 2,
          ),
          child: Icon(
            _definition.icon,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );

    final animatedChip = FadeScaleTransition(
      animation: _fadeScale,
      child: chip,
    );

    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sectionSpacing),
            child: animatedChip,
          ),
        ),
      ),
    );
  }
}
