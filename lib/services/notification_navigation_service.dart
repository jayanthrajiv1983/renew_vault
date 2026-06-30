import 'package:flutter/material.dart';

import '../screens/backup_screen.dart';
import '../shared/services/microinteraction_service.dart';

/// Routes the user when they tap a local notification.
class NotificationNavigationService {
  NotificationNavigationService._();

  static final NotificationNavigationService instance =
      NotificationNavigationService._();

  static const backupScreenPayload = 'backup_screen';

  String? _pendingPayload;

  void handlePayload(String? payload) {
    if (payload != backupScreenPayload) {
      return;
    }

    final navigator = rootNavigatorKey.currentState;
    if (navigator != null && navigator.mounted) {
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
      );
      return;
    }

    _pendingPayload = payload;
  }

  void consumePendingNavigation(BuildContext context) {
    if (_pendingPayload != backupScreenPayload) {
      return;
    }

    _pendingPayload = null;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
    );
  }
}
