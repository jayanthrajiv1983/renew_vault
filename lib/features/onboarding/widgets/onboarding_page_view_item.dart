import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../models/onboarding_page_content.dart';
import 'onboarding_icon.dart';

class OnboardingPageViewItem extends StatefulWidget {
  const OnboardingPageViewItem({
    super.key,
    required this.content,
    required this.isActive,
  });

  final OnboardingPageContent content;
  final bool isActive;

  @override
  State<OnboardingPageViewItem> createState() => _OnboardingPageViewItemState();
}

class _OnboardingPageViewItemState extends State<OnboardingPageViewItem>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 500);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant OnboardingPageViewItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: SingleChildScrollView(
          padding: AppSpacing.screenInsets,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height * 0.55,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OnboardingIcon(
                  style: widget.content.iconStyle,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: AppSpacing.screenPadding + 8),
                Text(
                  widget.content.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.content.subtitle != null) ...[
                  const SizedBox(height: AppSpacing.fieldLabelGap),
                  Text(
                    widget.content.subtitle!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.sectionSpacing),
                Text(
                  widget.content.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
