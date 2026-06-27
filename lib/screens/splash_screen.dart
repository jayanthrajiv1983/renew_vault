import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../theme/app_brand.dart';
import '../theme/app_spacing.dart';

/// Branded animated splash shown at app launch.
///
/// Displays logo, [AppBrand.displayName], and [AppBrand.tagline] with a subtle
/// staggered fade + scale, then navigates to [HomeScreen].
class SplashScreen extends StatefulWidget {
  const SplashScreen({this.onComplete, super.key});

  final VoidCallback? onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 900);
  static const _navigateDelay = Duration(milliseconds: 1800);

  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleScale;
  late final Animation<double> _taglineFade;
  late final Animation<double> _taglineScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.7, curve: Curves.easeOut),
    );
    _titleScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
    );
    _taglineScale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    await Future<void>.delayed(_navigateDelay);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _backgroundColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppBrand.primaryBlueDark
        : AppBrand.primaryBlue;
  }

  double _logoSize(BoxConstraints constraints, Size screenSize) {
    final shortestSide = screenSize.shortestSide;
    final base = shortestSide >= 600 ? 160.0 : 128.0;
    final maxWidth = constraints.maxWidth * 0.4;
    return base.clamp(96.0, maxWidth);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = _backgroundColor(theme.brightness);
    final screenSize = MediaQuery.sizeOf(context);
    const titleColor = Colors.white;
    final taglineColor = Colors.white.withValues(alpha: 0.85);

    return Scaffold(
      backgroundColor: background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final logoSize = _logoSize(constraints, screenSize);

          return Center(
            child: Padding(
              padding: AppSpacing.screenInsets,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        AppBrand.logoAsset,
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                        semanticLabel: AppBrand.name,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.screenPadding),
                  FadeTransition(
                    opacity: _titleFade,
                    child: ScaleTransition(
                      scale: _titleScale,
                      child: Text(
                        AppBrand.displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.fieldLabelGap),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: ScaleTransition(
                      scale: _taglineScale,
                      child: Text(
                        AppBrand.tagline,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: taglineColor,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
