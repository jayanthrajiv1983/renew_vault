import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../services/settings_service.dart';
import '../theme/app_brand.dart';
import '../theme/app_spacing.dart';
import '../widgets/renew_vault_logo.dart';

/// Wraps the app and enforces biometric / device-credential lock when enabled.
class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _lockService = AppLockService.instance;

  bool _isUnlocked = false;
  bool _isAuthenticating = false;
  bool _hasBiometrics = false;
  bool _deviceSupported = false;
  bool? _lastKnownAppLockEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SettingsService.instance.addListener(_onSettingsChanged);
    _lastKnownAppLockEnabled = _lockService.isAppLockEnabled();
    _initializeLockState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  Future<void> _initializeLockState() async {
    if (!_lockService.isAppLockEnabled()) {
      if (mounted) {
        setState(() => _isUnlocked = true);
      }
      return;
    }

    _deviceSupported = await _lockService.isDeviceSupported();
    _hasBiometrics = await _lockService.canCheckBiometrics();

    if (!mounted) {
      return;
    }

    setState(() => _isUnlocked = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptAuth();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isAuthenticating) {
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _lockService.recordBackground();
      return;
    }

    if (state != AppLifecycleState.resumed) {
      return;
    }

    if (!_lockService.isAppLockEnabled()) {
      if (!_isUnlocked && mounted) {
        setState(() => _isUnlocked = true);
      }
      return;
    }

    if (_lockService.isLockRequiredOnResume()) {
      if (mounted) {
        setState(() => _isUnlocked = false);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptAuth();
      });
    }
  }

  Future<void> _promptAuth() async {
    if (!mounted || _isUnlocked || _isAuthenticating) {
      return;
    }

    if (!_lockService.isAppLockEnabled()) {
      setState(() => _isUnlocked = true);
      return;
    }

    setState(() => _isAuthenticating = true);

    final success = await _lockService.authenticate();

    if (!mounted) {
      return;
    }

    setState(() {
      _isAuthenticating = false;
      if (success) {
        _isUnlocked = true;
        _lockService.clearBackgroundTime();
      }
    });
  }

  void _onSettingsChanged() {
    if (!mounted) {
      return;
    }

    final enabled = _lockService.isAppLockEnabled();
    if (_lastKnownAppLockEnabled == enabled) {
      return;
    }
    _lastKnownAppLockEnabled = enabled;

    if (!enabled) {
      setState(() => _isUnlocked = true);
      return;
    }

    setState(() => _isUnlocked = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_lockService.isAppLockEnabled()) {
      return widget.child;
    }

    if (_isUnlocked) {
      return widget.child;
    }

    return _AppLockOverlay(
      isAuthenticating: _isAuthenticating,
      deviceSupported: _deviceSupported,
      hasBiometrics: _hasBiometrics,
      onUnlock: () => _promptAuth(),
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
                          fontWeight: FontWeight.w700,
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
