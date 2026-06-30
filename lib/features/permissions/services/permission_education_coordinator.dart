import 'package:flutter/material.dart';

import '../../../core/services/logging_service.dart';
import '../models/app_permission_type.dart';
import '../widgets/permission_education_dialog.dart';
import 'permission_education_service.dart';
import 'permission_request_service.dart';

enum PermissionFlowOutcome {
  proceed,
  cancelled,
}

/// Shows permission education once, then optionally triggers the system prompt.
class PermissionEducationCoordinator {
  PermissionEducationCoordinator._();

  static Future<PermissionFlowOutcome> prepare(
    BuildContext context,
    AppPermissionType type,
  ) async {
    await PermissionEducationService.instance.init();

    if (PermissionEducationService.instance.hasShownEducation(type)) {
      return PermissionFlowOutcome.proceed;
    }

    if (!context.mounted) {
      return PermissionFlowOutcome.cancelled;
    }

    final result = await showPermissionEducationDialog(context, type);
    await PermissionEducationService.instance.markEducationShown(type);

    if (result == PermissionEducationResult.notNow) {
      LoggingService.instance.logInfo(
        'PERMISSIONS',
        'User chose Not Now for ${type.name}',
      );
      return PermissionFlowOutcome.cancelled;
    }

    if (result != PermissionEducationResult.continueAction) {
      return PermissionFlowOutcome.cancelled;
    }

    await PermissionRequestService.instance.requestPermission(type);
    return PermissionFlowOutcome.proceed;
  }
}
