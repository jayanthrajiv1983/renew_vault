import 'dart:io';

import 'package:flutter/material.dart';

import '../services/family_service.dart';

String ownerInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

class OwnerAvatar extends StatelessWidget {
  const OwnerAvatar({
    super.key,
    required this.ownerName,
    this.radius = 14,
  });

  final String ownerName;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final member = FamilyService.instance.getByName(ownerName);
    final photoPath = member?.photoPath;
    final theme = Theme.of(context);

    if (photoPath != null && photoPath.isNotEmpty) {
      final file = File(photoPath);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.secondaryContainer,
      child: Text(
        ownerInitials(ownerName),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
