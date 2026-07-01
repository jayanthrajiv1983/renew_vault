import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/theme/app_text_styles.dart';
import '../core/theme/design_system.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Priority hero insight shown above the dashboard stat grid.
enum HeroInsightVariant {
  expired,
  upcoming,
  safe,
}

/// Resolves which hero insight to show from home-screen counts.
HeroInsightVariant resolveHeroInsight({
  required int expiredCount,
  required int expiringSoonCount,
}) {
  if (expiredCount > 0) {
    return HeroInsightVariant.expired;
  }
  if (expiringSoonCount > 0) {
    return HeroInsightVariant.upcoming;
  }
  return HeroInsightVariant.safe;
}

/// Premium flat hero card with pastel gradients matching [DashboardStatCard].
class HeroInsightCard extends StatelessWidget {
  const HeroInsightCard({
    super.key,
    required this.expiredCount,
    required this.expiringSoonCount,
    required this.onReviewExpired,
    required this.onViewUpcoming,
    required this.onViewVault,
  });

  final int expiredCount;
  final int expiringSoonCount;
  final VoidCallback onReviewExpired;
  final VoidCallback onViewUpcoming;
  final VoidCallback onViewVault;

  static const EdgeInsets _padding = AppDesignTokens.cardInsets;
  static const double _iconTextGap = AppDesignTokens.space12;
  static const double _titleDescriptionGap = AppDesignTokens.space8;

  @override
  Widget build(BuildContext context) {
    final variant = resolveHeroInsight(
      expiredCount: expiredCount,
      expiringSoonCount: expiringSoonCount,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final spec = _HeroVisualSpec.forVariant(
      variant,
      colorScheme: colorScheme,
    );
    final count = switch (variant) {
      HeroInsightVariant.expired => expiredCount,
      HeroInsightVariant.upcoming => expiringSoonCount,
      HeroInsightVariant.safe => 0,
    };

    final onCta = switch (variant) {
      HeroInsightVariant.expired => onReviewExpired,
      HeroInsightVariant.upcoming => onViewUpcoming,
      HeroInsightVariant.safe => onViewVault,
    };

    final textStyles = AppTextStyles.of(context);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final useStackedLayout = constraints.maxWidth < 520;

        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              spec.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textStyles.itemTitle(
                color: spec.titleColor,
              ),
            ),
            const SizedBox(height: _titleDescriptionGap),
            Text(
              spec.description(count),
              maxLines: useStackedLayout ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: textStyles.secondaryInfo(
                color: spec.descriptionColor,
              ),
            ),
          ],
        );

        final icon = Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            spec.icon,
            size: AppDesignTokens.iconHero,
            color: spec.accentColor.withValues(alpha: 0.85),
          ),
        );

        final cta = spec.useFilledButton
            ? FilledButton(
                onPressed: onCta,
                style: FilledButton.styleFrom(
                  backgroundColor: spec.accentColor,
                  foregroundColor: spec.buttonForegroundColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignTokens.space12,
                    vertical: AppDesignTokens.space8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(spec.ctaLabel),
              )
            : TextButton(
                onPressed: onCta,
                style: TextButton.styleFrom(
                  foregroundColor: spec.accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignTokens.space12,
                    vertical: AppDesignTokens.space8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(spec.ctaLabel),
              );

        if (useStackedLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(width: _iconTextGap),
                  Expanded(child: textBlock),
                ],
              ),
              AppSpacing.gapTitleSubtitle,
              Align(
                alignment: Alignment.centerRight,
                child: cta,
              ),
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              icon,
              const SizedBox(width: _iconTextGap),
              Expanded(child: textBlock),
              const SizedBox(width: AppSpacing.titleSubtitleGap),
              Align(
                alignment: Alignment.center,
                child: cta,
              ),
            ],
          ),
        );
      },
    );

    final theme = Theme.of(context);

    final card = Material(
      color: Colors.transparent,
      elevation: AppDesignTokens.elevationDashboard,
      surfaceTintColor: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: spec.gradientColors,
          ),
          borderRadius: AppDesignTokens.radiusHeroBorder,
          border: AppDesignTokens.cardBorder(theme),
        ),
        child: Padding(
          padding: _padding,
          child: content,
        ),
      ),
    );

    return _FadeSlideIn(child: card);
  }
}

class _HeroVisualSpec {
  const _HeroVisualSpec({
    required this.gradientColors,
    required this.accentColor,
    required this.titleColor,
    required this.descriptionColor,
    required this.buttonForegroundColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.useFilledButton,
  });

  final List<Color> gradientColors;
  final Color accentColor;
  final Color titleColor;
  final Color descriptionColor;
  final Color buttonForegroundColor;
  final IconData icon;
  final String title;
  final String Function(int count) description;
  final String ctaLabel;
  final bool useFilledButton;

  static _HeroVisualSpec forVariant(
    HeroInsightVariant variant, {
    required ColorScheme colorScheme,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;
    switch (variant) {
      case HeroInsightVariant.expired:
        return _HeroVisualSpec(
          gradientColors: isDark
              ? const [Color(0xFF3D1F1F), Color(0xFF2A1818)]
              : const [Color(0xFFFEE2E2), Color(0xFFFFF5F5)],
          accentColor: AppColors.expiredColor(colorScheme),
          titleColor: AppColors.expiredOnContainer(colorScheme),
          descriptionColor: AppColors.expiredColor(colorScheme),
          buttonForegroundColor: Colors.white,
          icon: Icons.warning_amber_rounded,
          title: 'Action Required',
          description: (count) => count == 1
              ? 'You have 1 expired item that needs attention.'
              : 'You have $count expired items that need attention.',
          ctaLabel: 'Review Now',
          useFilledButton: true,
        );
      case HeroInsightVariant.upcoming:
        return _HeroVisualSpec(
          gradientColors: isDark
              ? const [Color(0xFF3D2E18), Color(0xFF2A2218)]
              : const [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
          accentColor: AppColors.expiringColor(colorScheme),
          titleColor: AppColors.expiringOnContainer(colorScheme),
          descriptionColor: AppColors.warningColor(colorScheme),
          buttonForegroundColor: isDark ? const Color(0xFF422006) : Colors.white,
          icon: Icons.calendar_month_rounded,
          title: 'Upcoming Renewals',
          description: (count) => count == 1
              ? '1 item expires within the next 30 days.'
              : '$count items expire within the next 30 days.',
          ctaLabel: 'View Items',
          useFilledButton: true,
        );
      case HeroInsightVariant.safe:
        return _HeroVisualSpec(
          gradientColors: isDark
              ? const [Color(0xFF1A3D2A), Color(0xFF152A20)]
              : const [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
          accentColor: AppColors.safeColor(colorScheme),
          titleColor: AppColors.safeOnContainer(colorScheme),
          descriptionColor: AppColors.safeColor(colorScheme),
          buttonForegroundColor: AppColors.safeColor(colorScheme),
          icon: Icons.celebration_rounded,
          title: "You're All Set",
          description: (_) => 'All items are currently up to date.',
          ctaLabel: 'View Vault',
          useFilledButton: false,
        );
    }
  }
}

class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child});

  final Widget child;

  static const Duration _duration = Duration(milliseconds: 400);

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _started = false;

  bool _shouldAnimate(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.disableAnimations) {
      return false;
    }
    return !SchedulerBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _FadeSlideIn._duration,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;

    if (!_shouldAnimate(context)) {
      _controller.value = 1;
      return;
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldAnimate(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
