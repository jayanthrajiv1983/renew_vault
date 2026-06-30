import 'package:flutter/material.dart';

import '../services/app_lock_controller.dart';
import '../services/app_lock_service.dart';
import '../theme/app_brand.dart';
import '../theme/app_spacing.dart';
import '../widgets/renew_vault_logo.dart';

/// Wraps the app and enforces biometric / device-credential lock when enabled.
///
/// Cold-start authentication is handled by [SplashScreen]. This gate blocks
/// [child] after resume and when app lock is enabled from Settings.
class AppLockGate extends StatefulWidget {
  const AppLockGate({
    required this.child,
    this.lockActive = true,
    super.key,
  });

  final Widget child;

  /// When false (e.g. during splash), lock enforcement is deferred.
  final bool lockActive;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _lockService = AppLockService.instance;
  final _lockController = AppLockController.instance;

  bool _isUnlocked = false;
  bool _isPromptingAuth = false;
  bool _hasBiometrics = false;
  bool _deviceSupported = false;

  bool get _shouldEnforceLock =>
      widget.lockActive && _lockService.isAppLockEnabled();

  bool get _showOverlay => _shouldEnforceLock && !_isUnlocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockController.addListener(_onAppLockPreferenceChanged);
    // Cold-start auth is handled by SplashScreen; gate locks on resume/settings.
    _isUnlocked = true;
    _loadDeviceCapabilities();
  }

  @override
  void didUpdateWidget(covariant AppLockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _lockController.removeListener(_onAppLockPreferenceChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadDeviceCapabilities() async {
    _deviceSupported = await _lockService.isDeviceSupported();
    _hasBiometrics = await _lockService.canCheckBiometrics();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (_isPromptingAuth || _lockService.authInProgress) {
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_shouldEnforceLock) {
        _lockService.recordBackground();
      }
      return;
    }

    if (state != AppLifecycleState.resumed) {
      return;
    }

    if (!_shouldEnforceLock) {
      if (!_isUnlocked && mounted) {
        setState(() => _isUnlocked = true);
      }
      return;
    }

    if (_lockService.isLockRequiredOnResume()) {
      _lockService.markLocked();
      if (mounted) {
        setState(() => _isUnlocked = false);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptAuth();
      });
    }
  }

  Future<void> _promptAuth() async {
    if (!mounted ||
        !_shouldEnforceLock ||
        _isUnlocked ||
        _isPromptingAuth ||
        _lockService.authInProgress) {
      return;
    }

    setState(() => _isPromptingAuth = true);

    final authenticated = await _lockService.authenticate();

    if (!mounted) {
      return;
    }

    setState(() {
      _isPromptingAuth = false;
      if (authenticated) {
        _isUnlocked = true;
        _lockService.clearBackgroundTime();
      } else {
        _isUnlocked = false;
      }
    });
  }

  void _onAppLockPreferenceChanged() {
    if (!mounted) {
      return;
    }

    final enabled = _lockController.preferenceEnabled;
    if (enabled == null) {
      return;
    }

    if (!enabled) {
      setState(() => _isUnlocked = true);
      return;
    }

    _lockService.markLocked();
    setState(() => _isUnlocked = false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDeviceCapabilities();
      if (mounted) {
        _promptAuth();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: _showOverlay,
          child: IgnorePointer(
            ignoring: _showOverlay,
            child: widget.child,
          ),
        ),
        if (_showOverlay)
          _AppLockOverlay(
            isAuthenticating: _isPromptingAuth || _lockService.authInProgress,
            deviceSupported: _deviceSupported,
            hasBiometrics: _hasBiometrics,
            onUnlock: () => _promptAuth(),
          ),
      ],
    );
  }
}

class _AppLockOverlay extends StatelessWidget {
  const _AppLockOverlay({
    required this.isAuthenticating,
    required this.deviceSupported,
    required this.hasBiometrics,
    required this.onUnlock,
  });

  final bool isAuthenticating;
  final bool deviceSupported;
  final bool hasBiometrics;
  final VoidCallback onUnlock;

  String get _subtitle {
    if (!deviceSupported) {
      return 'Device authentication is not available on this device.';
    }
    if (hasBiometrics) {
      return 'Use fingerprint, face unlock, or your device PIN to continue.';
    }
    return 'Use your device PIN or password to continue.';
  }

  IconData get _lockIcon {
    if (hasBiometrics) {
      return Icons.fingerprint;
    }
    return Icons.lock_outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.screenInsets,
          child: Column(
            children: [
              const Spacer(flex: 2),
              Card(
                elevation: AppSpacing.cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.cardBorderRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.cardPadding * 1.5,
                    vertical: AppSpacing.sectionSpacing * 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const RenewVaultLogo(
                        size: 88,
                        showTagline: true,
                      ),
                      AppSpacing.gapSection,
                      Icon(
                        _lockIcon,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                      AppSpacing.gapSection,
                      Text(
                        'Unlock ${AppBrand.name}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.fieldLabelGap),
                      Text(
                        _subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.gapSection,
                      if (isAuthenticating) ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.fieldLabelGap),
                        Text(
                          'Waiting for authentication…',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ] else ...[
                        FilledButton.icon(
                          onPressed: deviceSupported ? onUnlock : null,
                          icon: const Icon(Icons.lock_open_outlined),
                          label: const Text('Unlock'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.buttonBorderRadius,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
