import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/theme/app_text_styles.dart';
import '../theme/app_brand.dart';
import '../theme/app_colors.dart';

/// Semantic dashboard stat variants for the home screen grid.
enum DashboardStatType {
  totalItems,
  expiringSoon,
  expired,
  safe,
}

/// Premium Material 3 stat tile for the home dashboard grid.
class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.type,
    required this.label,
    required this.count,
    this.subtitle,
    this.onTap,
    this.animationIndex = 0,
  });

  final DashboardStatType type;
  final String label;
  final int count;
  final String? subtitle;
  final VoidCallback? onTap;
  final int animationIndex;

  static const double _borderRadius = 20;
  static const EdgeInsets _padding =
      EdgeInsets.fromLTRB(16, 12, 16, 16);
  static const double _iconContainerSize = 40;
  static const double _iconSize = 28;
  static const double _titleToValueGap = 10;
  static const double _valueToSubtitleGap = 4;
  static const double _subtitleLineHeight = 14.4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = AppTextStyles.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final spec = _StatVisualSpec.forType(type, isDark: isDark);

    final card = Material(
      color: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: spec.gradientColors,
          ),
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_borderRadius),
          splashColor: spec.accentColor.withValues(alpha: 0.12),
          highlightColor: spec.accentColor.withValues(alpha: 0.06),
          child: Padding(
            padding: _padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        softWrap: true,
                        style: textStyles.dashboardTitle(
                          color: spec.titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatIconBadge(
                      icon: spec.icon,
                      accentColor: spec.accentColor,
                    ),
                  ],
                ),
                const SizedBox(height: _titleToValueGap),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$count',
                    maxLines: 1,
                    style: textStyles.dashboardNumber(
                      color: spec.valueColor(colorScheme),
                    ),
                  ),
                ),
                const SizedBox(height: _valueToSubtitleGap),
                SizedBox(
                  height: _subtitleLineHeight,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: subtitle != null
                        ? Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyles.dashboardSubtitle(
                              color: spec.subtitleColor,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return _StaggeredScaleIn(
      index: animationIndex,
      child: SizedBox.expand(child: card),
    );
  }
}

class _StatIconBadge extends StatelessWidget {
  const _StatIconBadge({
    required this.icon,
    required this.accentColor,
  });

  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: DashboardStatCard._iconContainerSize,
      height: DashboardStatCard._iconContainerSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accentColor.withValues(alpha: 0.12),
        ),
        child: Icon(
          icon,
          size: DashboardStatCard._iconSize,
          color: accentColor.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _StatVisualSpec {
  const _StatVisualSpec({
    required this.gradientColors,
    required this.accentColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.icon,
    required this.valueColor,
  });

  final List<Color> gradientColors;
  final Color accentColor;
  final Color titleColor;
  final Color subtitleColor;
  final IconData icon;
  final Color Function(ColorScheme colorScheme) valueColor;

  static _StatVisualSpec forType(
    DashboardStatType type, {
    required bool isDark,
  }) {
    switch (type) {
      case DashboardStatType.totalItems:
        return _StatVisualSpec(
          gradientColors: isDark
              ? const [Color(0xFF1A2B45), Color(0xFF121A28)]
              : const [Color(0xFFE8F0FE), Color(0xFFF5F8FF)],
          accentColor: AppBrand.primaryBlue,
          titleColor: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E3A8A),
          subtitleColor:
              isDark ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6),
          icon: Icons.inventory_2_rounded,
          valueColor: AppColors.statTotal,
        );
      case DashboardStatType.expiringSoon:
        return _StatVisualSpec(
          gradientColors: isDark
              ? const [Color(0xFF3D2E18), Color(0xFF2A2218)]
              : const [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
          accentColor: AppColors.statExpiringSoon,
          titleColor: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
          subtitleColor:
              isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706),
          icon: Icons.schedule_rounded,
          valueColor: (_) => AppColors.statExpiringSoon,
        );
      case DashboardStatType.expired:
        return _StatVisualSpec(
          gradientColors: isDark
              ? const [Color(0xFF3D1F1F), Color(0xFF2A1818)]
              : const [Color(0xFFFEE2E2), Color(0xFFFFF5F5)],
          accentColor: AppColors.statExpired,
          titleColor: isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B),
          subtitleColor:
              isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
          icon: Icons.warning_amber_rounded,
          valueColor: (_) => AppColors.statExpired,
        );
      case DashboardStatType.safe:
        return _StatVisualSpec(
          gradientColors: isDark
              ? const [Color(0xFF1A3D2A), Color(0xFF152A20)]
              : const [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
          accentColor: AppColors.statSafe,
          titleColor: isDark ? const Color(0xFFBBF7D0) : const Color(0xFF166534),
          subtitleColor:
              isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
          icon: Icons.verified_rounded,
          valueColor: (_) => AppColors.statSafe,
        );
    }
  }
}

class _StaggeredScaleIn extends StatefulWidget {
  const _StaggeredScaleIn({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  static const Duration _duration = Duration(milliseconds: 400);
  static const Duration _delayPerItem = Duration(milliseconds: 70);

  @override
  State<_StaggeredScaleIn> createState() => _StaggeredScaleInState();
}

class _StaggeredScaleInState extends State<_StaggeredScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
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
      duration: _StaggeredScaleIn._duration,
    );
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
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

    final delay = _StaggeredScaleIn._delayPerItem * widget.index;
    Future<void>.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
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

    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}
