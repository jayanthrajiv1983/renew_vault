import 'package:flutter/material.dart';

import '../models/add_item_prefill.dart';
import '../screens/add_item_screen.dart';
import '../services/renewal_creation_flow.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';

enum _CreateRenewalOption {
  manual,
  scanDocument,
  uploadDocument,
}

/// Shows the primary renewal creation bottom sheet and navigates to [AddItemScreen].
Future<void> showCreateRenewalBottomSheet(
  BuildContext context, {
  String? initialCategory,
}) async {
  final option = await showModalBottomSheet<_CreateRenewalOption>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: bottomSheetPadding(sheetContext),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create New Renewal',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              AppSpacing.gapSection,
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Add Manually'),
                subtitle: const Text('Start with an empty form'),
                onTap: () =>
                    Navigator.pop(sheetContext, _CreateRenewalOption.manual),
              ),
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: const Text('Scan Document'),
                subtitle: const Text('Use camera or gallery, then review OCR'),
                onTap: () => Navigator.pop(
                  sheetContext,
                  _CreateRenewalOption.scanDocument,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Upload Document'),
                subtitle: const Text('Pick an image or PDF from your device'),
                onTap: () => Navigator.pop(
                  sheetContext,
                  _CreateRenewalOption.uploadDocument,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (option == null || !context.mounted) {
    return;
  }

  switch (option) {
    case _CreateRenewalOption.manual:
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddItemScreen(
            launchMode: AddItemLaunchMode.manual,
            initialCategory: initialCategory,
          ),
        ),
      );
    case _CreateRenewalOption.scanDocument:
      final prefill = await RenewalCreationFlow.runScanDocumentFlow(context);
      if (prefill != null && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddItemScreen(
              prefill: prefill,
              initialCategory: initialCategory,
            ),
          ),
        );
      }
    case _CreateRenewalOption.uploadDocument:
      final prefill = await RenewalCreationFlow.runUploadDocumentFlow(context);
      if (prefill != null && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddItemScreen(
              prefill: prefill,
              initialCategory: initialCategory,
            ),
          ),
        );
      }
  }
}
