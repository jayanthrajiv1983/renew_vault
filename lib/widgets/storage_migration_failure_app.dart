import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_brand.dart';
import '../theme/app_theme.dart';
import '../utils/form_padding.dart';

/// Shown when encrypted storage migration fails before the main app starts.
class StorageMigrationFailureApp extends StatelessWidget {
  const StorageMigrationFailureApp({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: StorageMigrationFailureScreen(message: message),
    );
  }
}

class StorageMigrationFailureScreen extends StatefulWidget {
  const StorageMigrationFailureScreen({
    super.key,
    required this.message,
  });

  final String message;

  @override
  State<StorageMigrationFailureScreen> createState() =>
      _StorageMigrationFailureScreenState();
}

class _StorageMigrationFailureScreenState
    extends State<StorageMigrationFailureScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showMigrationFailureDialog(context);
    });
  }

  Future<void> _showMigrationFailureDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: dialogInsetPadding(dialogContext),
          icon: const Icon(Icons.lock_reset_outlined),
          title: const Text('Unable to secure your data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.message),
              const SizedBox(height: 16),
              const Text(
                'You can try:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Restore from a backup file if you have one\n'
                '• Clear app storage in system settings, then reopen the app\n'
                '• Reinstall the app (this removes local data on the device)',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                SystemNavigator.pop();
              },
              child: const Text('Close app'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Preparing secure storage…',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
