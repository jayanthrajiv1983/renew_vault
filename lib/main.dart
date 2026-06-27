import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_brand.dart';
import 'theme/app_theme.dart';
import 'services/family_service.dart';
import 'services/notification_service.dart';
import 'services/ocr_correction_service.dart';
import 'services/settings_service.dart';
import 'services/storage_migration_service.dart';
import 'services/storage_service.dart';
import 'widgets/app_lock_gate.dart';
import 'widgets/privacy_protection_gate.dart';
import 'widgets/storage_migration_failure_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final migrationResult =
      await StorageMigrationService.instance.runMigrationIfNeeded();
  if (!migrationResult.success) {
    runApp(
      StorageMigrationFailureApp(
        message: migrationResult.message ??
            'Your local data could not be migrated to encrypted storage.',
      ),
    );
    return;
  }

  await StorageService.instance.init();
  await FamilyService.instance.init();
  await SettingsService.instance.init();
  await OcrCorrectionService.instance.init();
  await ThemeProvider.instance.init();
  await NotificationService().initialize();
  await NotificationService.instance.rescheduleAllReminders();
  runApp(const RenewVaultApp());
}

class RenewVaultApp extends StatefulWidget {
  const RenewVaultApp({super.key});

  @override
  State<RenewVaultApp> createState() => _RenewVaultAppState();
}

class _RenewVaultAppState extends State<RenewVaultApp> {
  bool _splashComplete = false;

  void _onSplashComplete() {
    if (_splashComplete) {
      return;
    }
    setState(() => _splashComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) {
        return MaterialApp(
          title: AppBrand.name,
          debugShowCheckedModeBanner: false,
          themeMode: ThemeProvider.instance.themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          builder: (context, child) {
            final appChild = child ?? const SizedBox.shrink();
            if (!_splashComplete) {
              return appChild;
            }
            return PrivacyProtectionGate(
              child: AppLockGate(child: appChild),
            );
          },
          home: SplashScreen(onComplete: _onSplashComplete),
        );
      },
    );
  }
}
