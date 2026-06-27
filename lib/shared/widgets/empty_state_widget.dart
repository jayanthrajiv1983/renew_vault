import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/app_spacing.dart';

/// Reusable centered empty-state layout for lists, search, and detail screens.
///
/// Displays an optional illustration or icon, a bold title, optional subtitle,
/// and an optional call-to-action. Content is constrained on wide layouts
/// (tablets) and animates in with a subtle fade + slide when motion is allowed.
///
/// Provide visual content via [illustration] (preferred for large artwork,
/// SVG/image assets, or custom widgets) or [icon] (for simple glyphs such as
/// [Icon]). When both are set, [illustration] takes precedence.
///
/// The CTA button is shown only when both [buttonText] and [onButtonPressed]
/// are provided.
///
/// Use [EmptyStateWidget.compact] for inline section placeholders inside lists
/// or chart cards where a full illustration is not needed.
class EmptyStateWidget extends StatefulWidget {
  const EmptyStateWidget({
    super.key,
    this.illustration,
    this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.semanticLabel,
    this.excludeVisualFromSemantics = true,
  }) : compact = false;

  /// Inline empty copy for list sections and chart placeholders.
  const EmptyStateWidget.compact({
    super.key,
    required this.title,
    this.subtitle,
    this.semanticLabel,
  })  : illustration = null,
        icon = null,
        buttonText = null,
        onButtonPressed = null,
        excludeVisualFromSemantics = true,
        compact = true;

  /// Large illustration or custom artwork shown above the title.
  final Widget? illustration;

  /// Alternate visual slot; used when [illustration] is null.
  final Widget? icon;

  /// Primary empty-state heading.
  final String title;

  /// Optional secondary descriptive copy below [title].
  final String? subtitle;

  /// Label for the optional call-to-action button.
  final String? buttonText;

  /// Invoked when the CTA button is pressed.
  final VoidCallback? onButtonPressed;

  /// Screen-reader label for the entire empty state. Defaults to a combination
  /// of [title], [subtitle], and [buttonText] when omitted.
  final String? semanticLabel;

  /// When true, decorative [illustration]/[icon] widgets are excluded from the
  /// accessibility tree.
  final bool excludeVisualFromSemantics;

  /// When true, renders a compact text-only placeholder without entrance motion.
  final bool compact;

  static const double maxContentWidth = 440;

  /// Standard muted icon for full-page empty states; excluded from semantics.
  static Widget mutedIcon(
    BuildContext context,
    IconData icon, {
    double size = 80,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Icon(
        icon,
        size: size,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
      ),
    );
  }

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 400);
  static const _slideOffset = Offset(0, 0.06);

  AnimationController? _controller;
  Animation<double>? _fade;
  Animation<Offset>? _slide;
  bool _animationConfigured = false;

  @override
  void initState() {
    super.initState();
    if (!widget.compact) {
      _controller = AnimationController(
        vsync: this,
        duration: _animationDuration,
      );
      final curved = CurvedAnimation(
        parent: _controller!,
        curve: Curves.easeOut,
      );
      _fade = curved;
      _slide = Tween<Offset>(
        begin: _slideOffset,
        end: Offset.zero,
      ).animate(curved);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.compact || _animationConfigured || _controller == null) {
      return;
    }
    _animationConfigured = true;
    if (_shouldAnimate(context)) {
      _controller!.forward();
    } else {
      _controller!.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  bool _shouldAnimate(BuildContext context) {
    if (widget.compact) {
      return false;
    }
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.disableAnimations) {
      return false;
    }
    return !SchedulerBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  bool get _showButton =>
      widget.buttonText != null &&
      widget.buttonText!.isNotEmpty &&
      widget.onButtonPressed != null;

  Widget? get _visual {
    final visual = widget.illustration ?? widget.icon;
    if (visual == null) {
      return null;
    }
    if (!widget.excludeVisualFromSemantics) {
      return visual;
    }
    return ExcludeSemantics(child: visual);
  }

  String get _resolvedSemanticLabel {
    if (widget.semanticLabel != null && widget.semanticLabel!.isNotEmpty) {
      return widget.semanticLabel!;
    }
    final parts = <String>[widget.title];
    if (widget.subtitle != null && widget.subtitle!.isNotEmpty) {
      parts.add(widget.subtitle!);
    }
    if (_showButton) {
      parts.add(widget.buttonText!);
    }
    return parts.join('. ');
  }

  @override
  Widget build(BuildContext context) {
    final content = Semantics(
      label: _resolvedSemanticLabel,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentMaxWidth = constraints.maxWidth.isFinite
                ? math.min(
                    constraints.maxWidth,
                    EmptyStateWidget.maxContentWidth,
                  )
                : EmptyStateWidget.maxContentWidth;

            final column = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _buildChildren(context),
            );

            final padded = Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact
                    ? AppSpacing.fieldLabelGap
                    : AppSpacing.screenPadding,
                vertical: widget.compact ? AppSpacing.fieldLabelGap : 0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: column,
              ),
            );

            if (!constraints.maxHeight.isFinite) {
              return padded;
            }

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: padded,
              ),
            );
          },
        ),
      ),
    );

    if (widget.compact || _controller == null) {
      return content;
    }

    return FadeTransition(
      opacity: _fade!,
      child: SlideTransition(
        position: _slide!,
        child: content,
      ),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visual = _visual;

    final titleStyle = widget.compact
        ? theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          )
        : theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          );

    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return [
      if (visual != null && !widget.compact) ...[
        visual,
        const SizedBox(height: AppSpacing.screenPadding),
      ],
      Text(
        widget.title,
        textAlign: TextAlign.center,
        style: titleStyle,
        maxLines: widget.compact ? 4 : 3,
        overflow: TextOverflow.visible,
        softWrap: true,
      ),
      if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
        SizedBox(
          height: widget.compact
              ? AppSpacing.fieldLabelGap
              : AppSpacing.sectionSpacing,
        ),
        Text(
          widget.subtitle!,
          textAlign: TextAlign.center,
          style: subtitleStyle,
          maxLines: 5,
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      ],
      if (_showButton) ...[
        const SizedBox(height: AppSpacing.screenPadding),
        FilledButton(
          onPressed: widget.onButtonPressed,
          child: Text(
            widget.buttonText!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ];
  }
}
