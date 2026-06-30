import 'package:flutter/material.dart';

import '../models/renewal_item.dart';
import '../screens/add_item_screen.dart';
import '../services/pending_delete_controller.dart';
import '../services/storage_service.dart';
import '../shared/widgets/success_overlay.dart';
import 'form_padding.dart';

/// Shared edit, duplicate, and delete flows for renewal list items.
class ItemActions {
  ItemActions._();

  static Future<void> openEdit(
    BuildContext context,
    RenewalItem item, {
    VoidCallback? onChanged,
  }) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(item: item),
      ),
    );

    if (updated == true) {
      onChanged?.call();
    }
  }

  static Future<void> confirmDelete(
    BuildContext context,
    RenewalItem item, {
    VoidCallback? onDeleted,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: dialogInsetPadding(context),
        title: const Text('Delete item?'),
        content: Text(
          'Delete "${item.title}"? You can undo this for a few seconds after deleting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await PendingDeleteController.instance.scheduleDelete(
      item,
      onUiChanged: onDeleted,
    );
  }

  static Future<void> duplicate(
    BuildContext context,
    RenewalItem item, {
    VoidCallback? onDuplicated,
  }) async {
    try {
      await StorageService.instance.duplicate(item);
    } catch (_) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await SuccessOverlay.showCelebration(context);
    if (!context.mounted) {
      return;
    }

    onDuplicated?.call();
  }
}
