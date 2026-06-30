import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../constants/categories.dart';
import '../models/add_item_prefill.dart';
import '../models/attachment_metadata.dart';
import '../models/family_member.dart';
import '../core/services/logging_service.dart';
import '../models/renewal_item.dart';
import '../services/attachment_service.dart';
import '../services/family_service.dart';
import '../services/milestone_service.dart';
import '../services/renewal_creation_flow.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../shared/widgets/success_overlay.dart';
import '../theme/app_spacing.dart';
import '../utils/app_snackbar.dart';
import '../widgets/attachment_form_section.dart';
import '../widgets/category_form_fields.dart';
import '../widgets/forms/category_form_controller.dart';
import '../widgets/reminder_interval_picker.dart';
import '../widgets/safe_form_scaffold.dart';
import 'ocr_review_screen.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({
    super.key,
    this.item,
    this.launchMode = AddItemLaunchMode.manual,
    this.prefill,
    this.initialCategory,
  });

  final RenewalItem? item;
  final AddItemLaunchMode launchMode;
  final AddItemPrefill? prefill;

  /// Pre-selects the category dropdown when creating a new item.
  final String? initialCategory;

  static List<String> get categories => Categories.ordered;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _categoryFormController = CategoryFormController();

  late String _itemId;
  late String _category;
  late String _owner;
  late Set<int> _selectedReminderDays;
  List<FamilyMember> _familyMembers = [];
  List<AttachmentMetadata> _attachments = [];
  final List<AttachmentMetadata> _removedAttachments = [];
  late Set<String> _persistedAttachmentIds;
  bool _saved = false;
  bool _scanning = false;

  bool get _isEditMode => widget.item != null;

  bool get _hasExistingFormData {
    if (_titleController.text.trim().isNotEmpty) {
      return true;
    }
    if (_categoryFormController.documentNumberController.text.trim().isNotEmpty) {
      return true;
    }
    if (_categoryFormController.registrationNumberController.text.trim().isNotEmpty) {
      return true;
    }
    if (_categoryFormController.policyNumberController.text.trim().isNotEmpty) {
      return true;
    }
    return _categoryFormController.primaryRenewalDateFor(_category) != null;
  }

  List<String> get _ownerOptions {
    final names = _familyMembers.map((member) => member.name).toList();
    if (_owner.isNotEmpty && !names.contains(_owner)) {
      names.insert(0, _owner);
    }
    return names;
  }

  @override
  void initState() {
    super.initState();
    _familyMembers = FamilyService.instance.getAll();
    final item = widget.item;
    if (item != null) {
      _itemId = item.id;
      _attachments = List<AttachmentMetadata>.from(item.attachments);
      _persistedAttachmentIds =
          item.attachments.map((attachment) => attachment.id).toSet();
      _titleController.text = item.title;
      _notesController.text = item.notes;
      _category = item.category;
      _owner = item.owner;
      _selectedReminderDays = item.reminderDays.toSet();
      _categoryFormController.loadFromItem(item);
    } else {
      _itemId = DateTime.now().millisecondsSinceEpoch.toString();
      _persistedAttachmentIds = {};
      final initialCategory = widget.initialCategory;
      _category = initialCategory != null &&
              AddItemScreen.categories.contains(initialCategory)
          ? initialCategory
          : AddItemScreen.categories.first;
      _owner = _defaultOwnerName();
      _selectedReminderDays =
          SettingsService.instance.getDefaultReminderDays().toSet();
    }

    final prefill = widget.prefill;
    if (prefill != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_applyPrefill(prefill));
      });
    }
  }

  Future<void> _applyPrefill(AddItemPrefill prefill) async {
    if (!mounted) {
      return;
    }

    if (prefill.reviewData != null) {
      applyOcrReviewToForm(
        data: prefill.reviewData!,
        currentCategory: _category,
        titleController: _titleController,
        categoryController: _categoryFormController,
        onCategoryChanged: _onCategoryChanged,
        onChanged: () => setState(() {}),
      );
    }

    await _attachFileFromPath(
      prefill.attachmentPath,
      prefill.fileType,
    );

    if (!mounted) {
      return;
    }

    final message = prefill.infoMessage ??
        (prefill.reviewData != null
            ? 'Scan applied. Review fields and save when ready.'
            : null);
    if (message != null) {
      AppSnackBar.show(context, message);
    }
  }

  String _defaultOwnerName() {
    final selfMember = _familyMembers.where((member) => member.id == 'self');
    if (selfMember.isNotEmpty) {
      return selfMember.first.name;
    }
    if (_familyMembers.isNotEmpty) {
      return _familyMembers.first.name;
    }
    return 'Self';
  }

  @override
  void dispose() {
    if (!_saved) {
      final sessionAdded = _attachments
          .where(
            (attachment) =>
                !_persistedAttachmentIds.contains(attachment.id),
          )
          .toList();
      if (sessionAdded.isNotEmpty) {
        unawaited(
          AttachmentService.instance
              .deleteAllAttachmentFilesForList(sessionAdded),
        );
      }
    }
    _titleController.dispose();
    _notesController.dispose();
    _categoryFormController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String value) {
    setState(() {
      _category = value;
      _categoryFormController.clearCategoryFields();
    });
  }

  Future<void> _scanDocument() async {
    if (_scanning) {
      return;
    }

    if (_category == 'Document') {
      await _categoryFormController.recordAllPendingOcrCorrections();
    }

    setState(() => _scanning = true);
    try {
      final prefill = await RenewalCreationFlow.runScanDocumentFlow(
        context,
        hasExistingData: _hasExistingFormData,
        currentCategory: _category,
      );
      if (prefill == null || !mounted) {
        return;
      }

      await _applyPrefill(prefill);
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  Future<void> _attachFileFromPath(
    String filePath,
    AttachmentFileType fileType,
  ) async {
    final sourceFile = File(filePath);
    if (!await sourceFile.exists()) {
      LoggingService.instance.logError(
        'OCR',
        'Attach failed attachment source missing ext=${fileType.extension} '
        'staging=${AttachmentService.instance.isOcrStagingPath(filePath)}',
        operation: 'OCR Attach',
      );
      if (mounted) {
        AppSnackBar.show(
          context,
          'Could not attach scan image. The file is no longer available.',
        );
      }
      return;
    }

    if (_attachments.isNotEmpty &&
        !AttachmentService.instance.canAddAttachmentCount(_attachments.length)) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace attachment?'),
          content: const Text(
            'Free plan allows one attachment per item. '
            'Replace the current attachment with the new file?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep existing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) {
        return;
      }

      final existing = _attachments.first;
      if (_persistedAttachmentIds.contains(existing.id)) {
        _removedAttachments.add(existing);
      } else {
        await AttachmentService.instance.deleteAttachmentFileOnly(existing);
      }
      setState(() => _attachments = []);
    }

    if (!mounted) {
      return;
    }

    try {
      final stub = AttachmentService.instance.stubItemForAttachments(
        renewalItemId: _itemId,
        attachments: _attachments,
      );
      final preferredName = p.basename(filePath).isNotEmpty
          ? p.basename(filePath)
          : 'document_${DateTime.now().millisecondsSinceEpoch}.${fileType.extension}';
      final saveResult = await AttachmentService.instance.saveFile(
        item: stub,
        sourceFile: sourceFile,
        fileType: fileType,
        preferredFileName: preferredName,
      );
      await AttachmentService.instance.cleanupOcrStagingFile(filePath);
      if (mounted) {
        setState(() => _attachments = saveResult.item.attachments);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Could not attach file: $e');
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dateError = _categoryFormController.validatePrimaryDate(_category);
    if (dateError != null) {
      AppSnackBar.show(context, dateError);
      return;
    }

    if (_category == 'Document') {
      await _categoryFormController.recordAllPendingOcrCorrections();
    }

    final renewalDate = _categoryFormController.primaryRenewalDateFor(_category)!;
    final reminderDays = _selectedReminderDays.toList()
      ..sort((a, b) => b.compareTo(a));

    final item = RenewalItem(
      id: _itemId,
      title: _titleController.text.trim(),
      category: _category,
      owner: _owner,
      renewalDate: renewalDate,
      notes: _notesController.text.trim(),
      reminderDays: reminderDays,
      notificationIds:
          _isEditMode ? widget.item!.notificationIds : const {},
      metadata: _categoryFormController.buildMetadata(_category),
      attachments: _attachments,
    );

    if (_isEditMode && _removedAttachments.isNotEmpty) {
      await AttachmentService.instance.deleteAllAttachmentFilesForList(
        _removedAttachments,
      );
    }

    await StorageService.instance.save(item);
    LoggingService.instance.logInfo(
      'RENEWALS',
      _isEditMode ? 'Item updated' : 'Item created',
    );
    _saved = true;

    if (!mounted) {
      return;
    }

    await SuccessOverlay.show(context, message: 'Item saved');
    if (!mounted) {
      return;
    }

    if (!_isEditMode) {
      final itemCount = StorageService.instance.getAll().length;
      final milestone =
          await MilestoneService.instance.checkAndConsume(itemCount);
      if (milestone != null && mounted) {
        await SuccessOverlay.showCelebration(
          context,
          message: milestone.message,
        );
      }
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(_isEditMode);
  }

  @override
  Widget build(BuildContext context) {
    return SafeFormScaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Item' : 'Add Item'),
      ),
      primaryLabel: _isEditMode ? 'Update' : 'Save',
      onPrimary: _save,
      child: Form(
        key: _formKey,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _scanning ? null : _scanDocument,
                icon: _scanning
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.document_scanner_outlined),
                label: Text(_scanning ? 'Scanning…' : 'Scan Document'),
              ),
              AppSpacing.gapField,
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              AppSpacing.gapField,
              DropdownMenuFormField<String>(
                key: ValueKey('category-$_category'),
                initialSelection: _category,
                label: const Text('Category'),
                dropdownMenuEntries: AddItemScreen.categories
                    .map(
                      (category) => DropdownMenuEntry(
                        value: category,
                        label: category,
                      ),
                    )
                    .toList(),
                onSelected: (value) {
                  if (value != null && value != _category) {
                    _onCategoryChanged(value);
                  }
                },
              ),
              AppSpacing.gapField,
              DropdownMenuFormField<String>(
                key: ValueKey('owner-$_owner-${_ownerOptions.length}'),
                initialSelection: _ownerOptions.contains(_owner)
                    ? _owner
                    : _ownerOptions.firstOrNull,
                label: const Text('Owner'),
                dropdownMenuEntries: _ownerOptions
                    .map(
                      (owner) => DropdownMenuEntry(
                        value: owner,
                        label: owner,
                      ),
                    )
                    .toList(),
                onSelected: (value) {
                  if (value != null) {
                    setState(() => _owner = value);
                  }
                },
              ),
              AppSpacing.gapField,
              CategoryFormFields(
                key: ValueKey('category-fields-$_category'),
                category: _category,
                controller: _categoryFormController,
                onChanged: () => setState(() {}),
              ),
              AppSpacing.gapField,
              ReminderIntervalPicker(
                title: 'Reminders',
                selectedDays: _selectedReminderDays,
                onChanged: (days) {
                  setState(() => _selectedReminderDays = days.toSet());
                },
              ),
              AppSpacing.gapField,
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              AppSpacing.gapField,
              AttachmentFormSection(
                renewalItemId: _itemId,
                attachments: _attachments,
                persistedAttachmentIds: _persistedAttachmentIds,
                onAttachmentsChanged: (attachments) {
                  setState(() => _attachments = attachments);
                },
                onPersistedAttachmentRemoved: (attachment) {
                  _removedAttachments.add(attachment);
                },
              ),
            ],
          ),
        ),
    );
  }
}
