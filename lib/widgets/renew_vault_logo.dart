import 'package:flutter/material.dart';

import '../theme/app_brand.dart';

/// Renders the official Renew Vault logo PNG.
///
/// Use [showTitle] for AppBar tablet branding and [showTagline] on About screens.
class RenewVaultLogo extends StatelessWidget {
  const RenewVaultLogo({
    super.key,
    this.size = 36,
    this.showTitle = false,
    this.showTagline = false,
  });

  final double size;
  final bool showTitle;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final icon = Image.asset(
      AppBrand.logoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: AppBrand.name,
    );

    if (!showTitle && !showTagline) {
      return icon;
    }

    if (showTagline && !showTitle) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          SizedBox(height: size * 0.2),
          Text(
            AppBrand.displayName,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size * 0.08),
          Text(
            AppBrand.tagline,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        if (showTitle) ...[
          SizedBox(width: size * 0.28),
          Text(
            AppBrand.displayName,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
