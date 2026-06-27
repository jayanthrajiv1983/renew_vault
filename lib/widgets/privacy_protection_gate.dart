import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/privacy_protection_service.dart';
import '../services/settings_service.dart';
import '../theme/app_brand.dart';
import '../widgets/renew_vault_logo.dart';

/// Hides app contents when backgrounded and syncs Android FLAG_SECURE.
class PrivacyProtectionGate extends StatefulWidget {
  const PrivacyProtectionGate({required this.child, super.key});

  final Widget child;

  @override
  State<PrivacyProtectionGate> createState() => _PrivacyProtectionGateState();
}

class _PrivacyProtectionGateState extends State<PrivacyProtectionGate>
    with WidgetsBindingObserver {
  final _protectionService = PrivacyProtectionService.instance;

  bool _showPrivacyOverlay = false;
  bool? _lastKnownProtectionEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SettingsService.instance.addListener(_onSettingsChanged);
    _lastKnownProtectionEnabled = _protectionService.isProtectionEnabled();
    _protectionService.syncSecureFlag();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_protectionService.isProtectionEnabled()) {
      if (_showPrivacyOverlay && mounted) {
        setState(() => _showPrivacyOverlay = false);
      }
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (!_showPrivacyOverlay && mounted) {
          setState(() => _showPrivacyOverlay = true);
        }
        _protectionService.syncSecureFlag();
      case AppLifecycleState.resumed:
        if (_showPrivacyOverlay && mounted) {
          setState(() => _showPrivacyOverlay = false);
        }
        _protectionService.syncSecureFlag();
      case AppLifecycleState.detached:
        break;
    }
  }

  void _onSettingsChanged() {
    if (!mounted) {
      return;
    }

    final enabled = _protectionService.isProtectionEnabled();
    if (_lastKnownProtectionEnabled == enabled) {
      return;
    }
    _lastKnownProtectionEnabled = enabled;

    if (!enabled && _showPrivacyOverlay) {
      setState(() => _showPrivacyOverlay = false);
    }

    _protectionService.syncSecureFlag();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_showPrivacyOverlay) const _PrivacyOverlay(),
      ],
    );
  }
}

class _PrivacyOverlay extends StatelessWidget {
  const _PrivacyOverlay();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: ColoredBox(
          color: colorScheme.surface.withValues(alpha: 0.92),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RenewVaultLogo(
                    size: 72,
                    showTagline: false,
                  ),
                  const SizedBox(height: 24),
                  Icon(
                    Icons.visibility_off_outlined,
                    size: 40,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppBrand.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Content hidden for your privacy',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
