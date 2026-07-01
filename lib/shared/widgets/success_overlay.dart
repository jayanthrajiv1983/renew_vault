import 'dart:async';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/haptic_feedback.dart';

/// Optional Lottie asset path. When added under `assets/`, import `lottie` and
/// swap [_AnimatedCheckmark] for `Lottie.asset` in [_buildIndicator].
const String? kSuccessOverlayLottieAsset = null;

/// Centered frosted-glass success overlay with animated checkmark.
///
/// Differs from [MicrointeractionOverlay]:
/// - Center-screen card with optional message (toast chip is icon-only, top-aligned)
/// - Frosted glass [BackdropFilter] card instead of elevated Material chip
/// - Custom animated checkmark (or optional Lottie when [kSuccessOverlayLottieAsset] is set)
///
enum SuccessOverlayVariant { standard, celebration }

/// Replaces any in-flight [SuccessOverlay] so overlays never stack.
class SuccessOverlayCoordinator {
  SuccessOverlayCoordinator._();

  static final SuccessOverlayCoordinator instance =
      SuccessOverlayCoordinator._();

  OverlayEntry? _currentEntry;
  Completer<void>? _currentCompleter;
  VoidCallback? _requestGracefulExit;
  Future<void>? _insertOperation;

  /// Dismisses any active [MicrointeractionOverlay] when set by [MicrointeractionService].
  static VoidCallback? dismissMicrointeractionPeer;

  void dismissCurrent() => _dismissCurrent(immediate: true);

  void registerGracefulExit(VoidCallback requestExit) {
    _requestGracefulExit = requestExit;
  }

  void unregisterGracefulExit(VoidCallback requestExit) {
    if (_requestGracefulExit == requestExit) {
      _requestGracefulExit = null;
    }
  }

  Future<void> insert({
    required OverlayState overlayState,
    required Widget Function(VoidCallback onDismissed) builder,
  }) async {
    final previousOperation = _insertOperation;
    final operationCompleter = Completer<void>();
    _insertOperation = operationCompleter.future;

    if (previousOperation != null) {
      await previousOperation;
    }

    try {
      dismissMicrointeractionPeer?.call();
      await _awaitPreviousDismiss();

      final completer = Completer<void>();
      late OverlayEntry entry;

      entry = OverlayEntry(
        builder: (overlayContext) => builder(() {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
            _requestGracefulExit = null;
            if (!completer.isCompleted) {
              completer.complete();
            }
            _currentCompleter = null;
          }
        }),
      );

      _currentEntry = entry;
      _currentCompleter = completer;
      overlayState.insert(entry);
      return completer.future;
    } finally {
      if (!operationCompleter.isCompleted) {
        operationCompleter.complete();
      }
    }
  }

  Future<void> _awaitPreviousDismiss() async {
    final entry = _currentEntry;
    final completer = _currentCompleter;
    final requestExit = _requestGracefulExit;

    if (entry == null || completer == null) {
      return;
    }

    if (requestExit != null) {
      requestExit();
      await completer.future;
      return;
    }

    _dismissCurrent(immediate: true);
  }

  void _dismissCurrent({required bool immediate}) {
    final entry = _currentEntry;
    if (entry == null) {
      return;
    }

    entry.remove();
    _currentEntry = null;
    _requestGracefulExit = null;
    _currentCompleter?.complete();
    _currentCompleter = null;
  }
}

/// Can be used directly in an [OverlayEntry] or via [SuccessOverlay.show].
class SuccessOverlay extends StatefulWidget {
  const SuccessOverlay({
    super.key,
    required this.onDismissed,
    this.message,
    this.holdDuration,
    this.skipAnimation = false,
    this.variant = SuccessOverlayVariant.standard,
  });

  static const enterDuration = Duration(milliseconds: 300);
  static const exitDuration = Duration(milliseconds: 300);
  static const standardHoldDuration = Duration(milliseconds: 1700);
  static const celebrationHoldDuration = Duration(milliseconds: 2000);
  static const celebrationCheckDuration = Duration(milliseconds: 300);

  /// Total visible time: enter + hold + exit.
  static const standardDuration = Duration(
    milliseconds: 300 + 1700 + 300,
  );
  static const celebrationDuration = Duration(
    milliseconds: 300 + 300 + 2000 + 300,
  );

  static Duration holdForVariant(SuccessOverlayVariant variant) {
    return variant == SuccessOverlayVariant.celebration
        ? celebrationHoldDuration
        : standardHoldDuration;
  }

  /// Inserts a [SuccessOverlay] into the root overlay and completes when dismissed.
  static Future<void> show(
    BuildContext context, {
    String? message,
    Duration? holdDuration,
    SuccessOverlayVariant variant = SuccessOverlayVariant.standard,
  }) {
    return _insert(
      context,
      message: message,
      holdDuration: holdDuration ?? holdForVariant(variant),
      variant: variant,
    );
  }

  /// Celebration variant: fade/scale enter, sequential checkmark draw, hold, fade out.
  static Future<void> showCelebration(
    BuildContext context, {
    String message = 'Item duplicated',
    Duration? holdDuration,
  }) {
    return show(
      context,
      message: message,
      holdDuration: holdDuration ?? celebrationHoldDuration,
      variant: SuccessOverlayVariant.celebration,
    );
  }

  static Future<void> _insert(
    BuildContext context, {
    String? message,
    required Duration holdDuration,
    required SuccessOverlayVariant variant,
  }) {
    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) {
      return Future<void>.value();
    }

    final skipAnimation = _shouldSkipAnimation(context);

    return SuccessOverlayCoordinator.instance.insert(
      overlayState: overlayState,
      builder: (onDismissed) => SuccessOverlay(
        key: UniqueKey(),
        message: message,
        holdDuration: holdDuration,
        skipAnimation: skipAnimation,
        variant: variant,
        onDismissed: onDismissed,
      ),
    );
  }

  final VoidCallback onDismissed;
  final String? message;
  final Duration? holdDuration;
  final bool skipAnimation;
  final SuccessOverlayVariant variant;

  static bool _shouldSkipAnimation(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery != null && mediaQuery.disableAnimations) {
      return true;
    }

    return SchedulerBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with TickerProviderStateMixin {
  static const _standardCheckDuration = Duration(milliseconds: 280);

  bool get _isCelebration =>
      widget.variant == SuccessOverlayVariant.celebration;

  Duration get _holdDuration =>
      widget.holdDuration ??
      SuccessOverlay.holdForVariant(widget.variant);

  Duration get _checkDuration => _isCelebration
      ? SuccessOverlay.celebrationCheckDuration
      : _standardCheckDuration;

  Duration get _reducedMotionHoldDuration {
    if (_isCelebration) {
      return _holdDuration +
          SuccessOverlay.enterDuration +
          _checkDuration +
          SuccessOverlay.exitDuration;
    }
    return _holdDuration +
        SuccessOverlay.enterDuration +
        SuccessOverlay.exitDuration;
  }

  late final AnimationController _overlayController;
  late final Animation<double> _fadeScale;
  late final AnimationController _checkController;
  late final VoidCallback _gracefulExitHandler;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    if (_isCelebration) {
      AppHaptics.onCelebration();
    } else {
      AppHaptics.onSuccess();
    }

    _overlayController = AnimationController(vsync: this);
    _fadeScale = CurvedAnimation(
      parent: _overlayController,
      curve: _isCelebration ? Curves.easeOutBack : Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _checkController = AnimationController(
      vsync: this,
      duration: _checkDuration,
    );

    _gracefulExitHandler = _requestGracefulExit;
    SuccessOverlayCoordinator.instance.registerGracefulExit(
      _gracefulExitHandler,
    );

    unawaited(_runSequence());
  }

  void _requestGracefulExit() {
    if (!mounted || _isExiting) {
      return;
    }
    unawaited(_exit());
  }

  void _resetControllers() {
    _overlayController
      ..stop()
      ..value = 0.0;
    _checkController
      ..stop()
      ..value = 0.0;
    _isExiting = false;
  }

  Future<void> _runSequence() async {
    _resetControllers();

    if (widget.skipAnimation) {
      _overlayController.value = 1.0;
      _checkController.value = 1.0;
      await Future<void>.delayed(_reducedMotionHoldDuration);
      if (!mounted || _isExiting) {
        return;
      }
      await _exit();
      return;
    }

    _overlayController.duration = SuccessOverlay.enterDuration;
    _checkController.duration = _checkDuration;

    if (_isCelebration) {
      await _overlayController.forward();
      if (!mounted || _isExiting) {
        return;
      }

      await _checkController.forward();
    } else {
      await Future.wait<void>([
        _overlayController.forward(),
        _checkController.forward(),
      ]);
    }
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

    _overlayController.duration = SuccessOverlay.exitDuration;
    await _overlayController.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    SuccessOverlayCoordinator.instance.unregisterGracefulExit(
      _gracefulExitHandler,
    );
    _overlayController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  Color _successColor(ColorScheme colorScheme) => colorScheme.safeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final successColor = _successColor(colorScheme);
    final semanticLabel = widget.message ?? 'Success';

    final card = Semantics(
      liveRegion: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: AppSpacing.cardBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.78),
              borderRadius: AppSpacing.cardBorderRadius,
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.cardPadding + 4,
                vertical: AppSpacing.cardPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIndicator(successColor),
                  if (widget.message != null) ...[
                    const SizedBox(height: AppSpacing.fieldLabelGap),
                    Text(
                      widget.message!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return IgnorePointer(
      child: SafeArea(
        child: Center(
          child: FadeScaleTransition(
            animation: _fadeScale,
            child: card,
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(Color successColor) {
    final checkmarkSize = _isCelebration ? 64.0 : 56.0;

    return RepaintBoundary(
      child: TickerMode(
        enabled: true,
        child: AnimatedBuilder(
          animation: _checkController,
          builder: (context, child) {
            return _AnimatedCheckmark(
              progress: _checkController.value,
              color: successColor,
              size: checkmarkSize,
              strokeFromBeginning: _isCelebration,
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedCheckmark extends StatelessWidget {
  const _AnimatedCheckmark({
    required this.progress,
    required this.color,
    this.size = 56,
    this.strokeFromBeginning = false,
  });

  final double progress;
  final Color color;
  final double size;
  final bool strokeFromBeginning;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CheckmarkPainter(
          progress: progress,
          color: color,
          strokeFromBeginning: strokeFromBeginning,
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({
    required this.progress,
    required this.color,
    this.strokeFromBeginning = false,
  });

  final double progress;
  final Color color;
  final bool strokeFromBeginning;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circleProgress = strokeFromBeginning
        ? (progress / 0.35).clamp(0.0, 1.0)
        : (progress * 2.5).clamp(0.0, 1.0);
    if (circleProgress > 0) {
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.14 * circleProgress)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        center,
        radius * (0.82 + 0.18 * circleProgress),
        fillPaint,
      );

      final ringPaint = Paint()
        ..color = color.withValues(alpha: 0.35 + 0.65 * circleProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, radius * 0.84, ringPaint);
    }

    final checkProgress = strokeFromBeginning
        ? ((progress - 0.35) / 0.65).clamp(0.0, 1.0)
        : ((progress - 0.25) / 0.75).clamp(0.0, 1.0);
    if (checkProgress <= 0) {
      return;
    }

    final checkPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final start = Offset(size.width * 0.27, size.height * 0.52);
    final mid = Offset(size.width * 0.43, size.height * 0.68);
    final end = Offset(size.width * 0.73, size.height * 0.32);

    final path = Path()..moveTo(start.dx, start.dy);

    if (checkProgress <= 0.45) {
      final t = checkProgress / 0.45;
      final current = Offset.lerp(start, mid, t)!;
      path.lineTo(current.dx, current.dy);
    } else {
      path.lineTo(mid.dx, mid.dy);
      final t = (checkProgress - 0.45) / 0.55;
      final current = Offset.lerp(mid, end, t)!;
      path.lineTo(current.dx, current.dy);
    }

    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeFromBeginning != strokeFromBeginning;
  }
}
