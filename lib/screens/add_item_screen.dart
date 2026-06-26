import 'package:flutter/material.dart';

import '../models/family_member.dart';
import '../models/renewal_item.dart';
import '../services/family_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/category_form_fields.dart';
import '../widgets/forms/category_form_controller.dart';
import '../widgets/reminder_interval_picker.dart';
import '../widgets/safe_form_scaffold.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key, this.item});

  final RenewalItem? item;

  static const categories = [
    'Appliance',
    'Vehicle',
    'Insurance',
    'Document',
    'Tax',
    'Other',
  ];

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _categoryFormController = CategoryFormController();

  late String _category;
  late String _owner;
  late Set<int> _selectedReminderDays;
  List<FamilyMember> _familyMembers = [];

  bool get _isEditMode => widget.item != null;

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
      _titleController.text = item.title;
      _notesController.text = item.notes;
      _category = item.category;
      _owner = item.owner;
      _selectedReminderDays = item.reminderDays.toSet();
      _categoryFormController.loadFromItem(item);
    } else {
      _category = AddItemScreen.categories.first;
      _owner = _defaultOwnerName();
      _selectedReminderDays =
          SettingsService.instance.getDefaultReminderDays().toSet();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dateError = _categoryFormController.validatePrimaryDate(_category);
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dateError)),
      );
      return;
    }

    if (_category == 'Document') {
      await _categoryFormController.recordAllPendingOcrCorrections();
    }

    final renewalDate = _categoryFormController.primaryRenewalDateFor(_category)!;
    final reminderDays = _selectedReminderDays.toList()
      ..sort((a, b) => b.compareTo(a));

    final item = RenewalItem(
      id: _isEditMode
          ? widget.item!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _category,
      owner: _owner,
      renewalDate: renewalDate,
      notes: _notesController.text.trim(),
      reminderDays: reminderDays,
      notificationIds:
          _isEditMode ? widget.item!.notificationIds : const {},
      metadata: _categoryFormController.buildMetadata(_category),
    );

    await StorageService.instance.save(item);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(_isEditMode);
  }

  @override
  Widget build(BuildContext context) {
    return SafeFormScaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Renewal' : 'Add Item'),
      ),
      primaryLabel: _isEditMode ? 'Update' : 'Save',
      onPrimary: _save,
      child: Form(
        key: _formKey,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
            ],
          ),
        ),
    );
  }
}
