import 'package:flutter/material.dart';

import '../core/services/logging_service.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/onboarding/services/onboarding_service.dart';
import '../screens/home_screen.dart';
import '../services/app_lock_service.dart';
import '../services/settings_service.dart';
import '../theme/app_brand.dart';
import '../theme/app_spacing.dart';

/// Branded animated splash shown at app launch.
///
/// Displays logo, [AppBrand.displayName], and [AppBrand.tagline] with a subtle
/// staggered fade + scale, then authenticates when app lock is enabled before
/// navigating to [HomeScreen].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 900);
  static const _navigateDelay = Duration(milliseconds: 1800);

  final _splashStopwatch = Stopwatch()..start();

  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleScale;
  late final Animation<double> _taglineFade;
  late final Animation<double> _taglineScale;

  bool _isAuthenticating = false;
  bool _authFailed = false;

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

    LoggingService.instance.logInfo('APP', 'Splash screen displayed');
    _controller.forward();
    _startup();
  }

  Future<void> _startup() async {
    if (SettingsService.instance.getAppLockEnabled()) {
      final authenticated = await _authenticateForStartup();
      if (!authenticated || !mounted) {
        return;
      }
    }

    await Future<void>.delayed(_navigateDelay);
    if (!mounted) {
      return;
    }

    LoggingService.instance.logInfo('APP', 'Application startup complete');
    LoggingService.instance.logPerf(
      'splash_to_home',
      _splashStopwatch.elapsedMilliseconds,
    );
    final nextScreen = OnboardingService.instance.isCompleted
        ? const HomeScreen()
        : const OnboardingScreen();
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => nextScreen),
    );
  }

  Future<bool> _authenticateForStartup() async {
    if (!mounted) {
      return false;
    }

    setState(() {
      _isAuthenticating = true;
      _authFailed = false;
    });

    final authenticated = await AppLockService.instance.authenticate();

    if (!mounted) {
      return false;
    }

    setState(() {
      _isAuthenticating = false;
      _authFailed = !authenticated;
    });

    return authenticated;
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
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                          fontWeight: FontWeight.w600,
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
                  if (_isAuthenticating) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    const SizedBox(height: AppSpacing.fieldLabelGap),
                    Text(
                      'Waiting for authentication…',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: taglineColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (_authFailed) ...[
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    Text(
                      'Authentication required to continue',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: taglineColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.fieldLabelGap),
                    FilledButton.icon(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final ok = await _authenticateForStartup();
                        if (!mounted || !ok) {
                          return;
                        }
                        await navigator.pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                OnboardingService.instance.isCompleted
                                    ? const HomeScreen()
                                    : const OnboardingScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.lock_open_outlined),
                      label: const Text('Unlock'),
                      style: FilledButton.styleFrom(
                        foregroundColor: AppBrand.primaryBlue,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
