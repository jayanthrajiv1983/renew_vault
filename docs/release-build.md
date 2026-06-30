# Renew Vault — Release Build Guide

This document describes how to produce hardened production builds of Renew Vault for Android and iOS.

## Prerequisites

- Flutter SDK installed and on your `PATH`
- Android SDK with build tools (for Android)
- Xcode (for iOS, macOS only)
- A configured release signing key for store submission (see [Flutter Android deployment](https://docs.flutter.dev/deployment/android))

## Android release build

### Standard App Bundle (recommended for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### APK (side-loading or internal testing)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Release hardening (already configured)

The Android release build enables:

- **R8 minification** (`minifyEnabled true`) — shrinks and obfuscates Java/Kotlin bytecode
- **Resource shrinking** (`shrinkResources true`) — removes unused resources
- **ProGuard rules** — `android/app/proguard-rules.pro` keeps Firebase, Hive, Google Sign-In, and ML Kit classes

## Dart obfuscation

Obfuscate Dart symbols and split debug symbols for Crashlytics / Play Console deobfuscation:

```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=debug-info/
```

For APK:

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=debug-info/
```

**Important:** Archive the `debug-info/` folder for each published build. Upload the symbols to Firebase Crashlytics and/or the Play Console so crash reports remain readable.

## iOS release build

```bash
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=debug-info/
```

Requires valid code signing and provisioning in Xcode.

## What changes in release mode

| Area | Debug / profile | Release |
|------|-----------------|---------|
| `debugPrint` / console logging | Enabled | Disabled (`kDebugMode`) |
| `LoggingService.logDebug` | Persisted | Suppressed |
| INFO / WARNING / ERROR logs | Persisted | Persisted |
| Settings → Debug Logs | Visible | Hidden |
| Settings → Beta Tester Tools | Visible | Hidden |
| Test Crash / Crashlytics test UI | Available in Beta Tools | Hidden with Beta Tools |

## Verification checklist

1. Run `flutter analyze` on changed Dart files.
2. Build release: `flutter build appbundle --release` (or `apk --release`).
3. Install on a device and confirm developer menus are absent.
4. Trigger a real error path and confirm Crashlytics receives reports (with symbols uploaded).
5. Smoke-test core flows: login/lock, add item, backup, notifications.

## Signing for production

Replace the debug signing config in `android/app/build.gradle.kts` with your release keystore before store submission. Never commit keystore files or passwords to version control.
