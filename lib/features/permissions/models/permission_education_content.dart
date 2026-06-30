import 'package:flutter/material.dart';

import 'app_permission_type.dart';

class PermissionEducationContent {
  const PermissionEducationContent({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

PermissionEducationContent permissionEducationContentFor(AppPermissionType type) {
  return switch (type) {
    AppPermissionType.camera => const PermissionEducationContent(
        title: 'Camera Access',
        description: 'Used to scan documents.',
        icon: Icons.document_scanner_rounded,
      ),
    AppPermissionType.notification => const PermissionEducationContent(
        title: 'Notifications',
        description: 'Used to remind you about important renewals.',
        icon: Icons.notifications_active_rounded,
      ),
    AppPermissionType.storage => const PermissionEducationContent(
        title: 'File Access',
        description: 'Used for attachments and backups.',
        icon: Icons.folder_open_rounded,
      ),
    AppPermissionType.biometric => const PermissionEducationContent(
        title: 'Biometric Security',
        description: 'Used to secure your vault.',
        icon: Icons.fingerprint_rounded,
      ),
  };
}
