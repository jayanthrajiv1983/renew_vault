import 'package:flutter/material.dart';

import '../../../theme/app_brand.dart';
import '../models/onboarding_page_content.dart';

class OnboardingIcon extends StatelessWidget {
  const OnboardingIcon({
    super.key,
    required this.style,
    required this.colorScheme,
  });

  final OnboardingIconStyle style;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      OnboardingIconStyle.shieldCalendar => _ShieldCalendarIcon(
          colorScheme: colorScheme,
        ),
      OnboardingIconStyle.notifications => _IconCircle(
          colorScheme: colorScheme,
          icon: Icons.notifications_active_rounded,
        ),
      OnboardingIconStyle.fingerprint => _IconCircle(
          colorScheme: colorScheme,
          icon: Icons.fingerprint_rounded,
        ),
      OnboardingIconStyle.cameraOcr => _IconCircle(
          colorScheme: colorScheme,
          icon: Icons.document_scanner_rounded,
        ),
      OnboardingIconStyle.rocket => _IconCircle(
          colorScheme: colorScheme,
          icon: Icons.rocket_launch_rounded,
        ),
    };
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.colorScheme,
    required this.icon,
  });

  final ColorScheme colorScheme;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primary.withValues(alpha: 0.18),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 56,
        color: colorScheme.primary,
      ),
    );
  }
}

class _ShieldCalendarIcon extends StatelessWidget {
  const _ShieldCalendarIcon({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer,
                  AppBrand.primaryBlue.withValues(alpha: 0.15),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Icon(
            Icons.shield_rounded,
            size: 64,
            color: colorScheme.primary,
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 22,
                color: AppBrand.accentOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
