import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_brand.dart';

/// Renders the Renew Vault logo from SVG asset or a [CustomPaint] fallback.
///
/// Use [showTitle] for AppBar tablet branding and [showTagline] on About screens.
class RenewVaultLogo extends StatelessWidget {
  const RenewVaultLogo({
    super.key,
    this.size = 36,
    this.showTitle = false,
    this.showTagline = false,
    this.useAsset = true,
    this.badgeBackground = true,
  });

  final double size;
  final bool showTitle;
  final bool showTagline;
  final bool useAsset;

  /// When true, wraps the icon in a circular primary-container badge (AppBar).
  final bool badgeBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final icon = _buildIcon(context);

    final badge = badgeBackground
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SizedBox(
              width: size * 0.62,
              height: size * 0.62,
              child: icon,
            ),
          )
        : SizedBox(width: size, height: size, child: icon);

    if (!showTitle && !showTagline) {
      return badge;
    }

    if (showTagline && !showTitle) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          SizedBox(height: size * 0.2),
          Text(
            AppBrand.name,
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
        badge,
        if (showTitle) ...[
          SizedBox(width: size * 0.28),
          Text(
            AppBrand.name,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIcon(BuildContext context) {
    if (useAsset) {
      return SvgPicture.asset(
        AppBrand.logoSvgAsset,
        fit: BoxFit.contain,
        semanticsLabel: AppBrand.name,
      );
    }

    return CustomPaint(
      painter: RenewVaultLogoPainter(
        brightness: Theme.of(context).brightness,
      ),
    );
  }
}

/// Vector fallback painter matching [AppBrand.logoSvgAsset].
class RenewVaultLogoPainter extends CustomPainter {
  RenewVaultLogoPainter({required this.brightness});

  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 512;
    canvas.scale(scale);

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppBrand.primaryBlue, AppBrand.primaryBlueDark],
      ).createShader(const Rect.fromLTWH(0, 0, 512, 512));
    canvas.drawCircle(const Offset(256, 256), 232, bgPaint);

    final ringPaint = Paint()
      ..color = AppBrand.accentOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(256, 256), radius: 200),
      -math.pi / 2,
      math.pi * 1.55,
      false,
      ringPaint,
    );

    final arrowPath = Path()
      ..moveTo(120, 340)
      ..lineTo(96, 360)
      ..lineTo(130, 372)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = AppBrand.accentOrange);

    final shieldPath = Path()
      ..moveTo(256, 108)
      ..lineTo(352, 148)
      ..lineTo(352, 252)
      ..cubicTo(352, 322, 256, 396, 256, 396)
      ..cubicTo(256, 396, 160, 322, 160, 252)
      ..lineTo(160, 148)
      ..close();

    canvas.drawPath(
      shieldPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFEFF6FF)],
        ).createShader(const Rect.fromLTWH(160, 108, 192, 288)),
    );
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = AppBrand.primaryBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(196, 188, 120, 32),
        const Radius.circular(6),
      ),
      Paint()..color = AppBrand.primaryBlue,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(196, 212, 120, 96),
        const Radius.circular(6),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(196, 212, 120, 96),
        const Radius.circular(6),
      ),
      Paint()
        ..color = AppBrand.primaryBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final ringPaint2 = Paint()..color = AppBrand.primaryBlueDark;
    for (final dx in [218.0, 256.0, 294.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx, 178, 8, 20),
          const Radius.circular(3),
        ),
        ringPaint2,
      );
    }

    final dotPaint = Paint()..color = AppBrand.primaryBlue.withValues(alpha: 0.35);
    for (final offset in [
      const Offset(218, 244),
      const Offset(256, 244),
      const Offset(294, 244),
      const Offset(218, 278),
      const Offset(294, 278),
    ]) {
      canvas.drawCircle(offset, 7, dotPaint);
    }
    canvas.drawCircle(const Offset(256, 278), 7, Paint()..color = AppBrand.green);

    canvas.drawCircle(const Offset(340, 340), 44, Paint()..color = AppBrand.green);

    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(318, 340)
        ..lineTo(334, 356)
        ..lineTo(364, 322),
      checkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RenewVaultLogoPainter oldDelegate) =>
      oldDelegate.brightness != brightness;
}
