import 'package:flutter/material.dart';

import '../../core/theme/design_system.dart';

/// Fixed-width leading icon column for item list cards ([RenewalCard] and variants).
///
/// Vertically centers a circular category icon against the full text block.
class ItemCardLeadingIcon extends StatelessWidget {
  const ItemCardLeadingIcon({
    super.key,
    required this.icon,
    required this.color,
  });

  static const double columnWidth = AppDesignTokens.renewalCardIconColumnSize;

  static const double _containerSize =
      AppDesignTokens.renewalCardIconColumnSize;
  static const double _iconSize = AppDesignTokens.iconLarge;
  static const double _backgroundAlpha = 0.12;
  static const double _tintAlpha = 0.85;

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: columnWidth,
      child: Center(
        child: SizedBox(
          width: _containerSize,
          height: _containerSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: _backgroundAlpha),
            ),
            child: Center(
              child: Icon(
                icon,
                size: _iconSize,
                color: color.withValues(alpha: _tintAlpha),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
