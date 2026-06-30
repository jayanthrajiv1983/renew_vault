import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/logging_service.dart';
import '../../../services/notification_service.dart';
import '../models/app_permission_type.dart';

/// Triggers platform permission prompts after the user accepts education.
class PermissionRequestService {
  PermissionRequestService._();

  static final PermissionRequestService instance = PermissionRequestService._();

  Future<void> requestPermission(AppPermissionType type) async {
    switch (type) {
      case AppPermissionType.camera:
        await _requestCamera();
      case AppPermissionType.notification:
        await NotificationService.instance.requestSystemPermissions();
      case AppPermissionType.storage:
        await _requestStorage();
      case AppPermissionType.biometric:
        break;
    }
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    LoggingService.instance.logInfo(
      'PERMISSIONS',
      'Camera permission result: $status',
    );
  }

  Future<void> _requestStorage() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final photosStatus = await Permission.photos.request();
      LoggingService.instance.logInfo(
        'PERMISSIONS',
        'Photos permission result: $photosStatus',
      );
    }

    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.request();
      LoggingService.instance.logInfo(
        'PERMISSIONS',
        'Storage permission result: $storageStatus',
      );
    }
  }
}
