import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../models/app_permission_type.dart';
import '../models/permission_education_content.dart';
import 'permission_education_card.dart';

enum PermissionEducationResult {
  continueAction,
  notNow,
}

Future<PermissionEducationResult?> showPermissionEducationDialog(
  BuildContext context,
  AppPermissionType type,
) {
  final content = permissionEducationContentFor(type);

  return showDialog<PermissionEducationResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: PermissionEducationCard(
        content: content,
        onContinue: () => Navigator.of(dialogContext).pop(
          PermissionEducationResult.continueAction,
        ),
        onNotNow: () => Navigator.of(dialogContext).pop(
          PermissionEducationResult.notNow,
        ),
      ),
    ),
  );
}
