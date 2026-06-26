import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_brand.dart';
import 'theme/app_theme.dart';
import 'services/family_service.dart';
import 'services/notification_service.dart';
import 'services/ocr_correction_service.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await StorageService.instance.init();
  await FamilyService.instance.init();
  await SettingsService.instance.init();
  await OcrCorrectionService.instance.init();
  await ThemeProvider.instance.init();
  await NotificationService().initialize();
  await NotificationService.instance.rescheduleAllReminders();
  runApp(const RenewVaultApp());
}

class RenewVaultApp extends StatelessWidget {
  const RenewVaultApp({super.key});

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
          home: const HomeScreen(),
        );
      },
    );
  }
}
