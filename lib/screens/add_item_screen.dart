import 'package:flutter/material.dart';

import '../models/renewal_item.dart';
import '../services/storage_service.dart';

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

  static const owners = [
    'Self',
    'Spouse',
    'Family',
    'Other',
  ];

  static const reminderOptions = <int, String>{
    30: '30 days before',
    15: '15 days before',
    7: '7 days before',
    1: '1 day before',
    0: 'On due date',
  };

  static const orderedReminderDays = [30, 15, 7, 1, 0];

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late String _category;
  late String _owner;
  DateTime? _renewalDate;
  late Set<int> _selectedReminderDays;

  bool get _isEditMode => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _titleController.text = item.title;
      _notesController.text = item.notes;
      _category = item.category;
      _owner = item.owner;
      _renewalDate = item.renewalDate;
      _selectedReminderDays = item.reminderDays.toSet();
    } else {
      _category = AddItemScreen.categories.first;
      _owner = 'Self';
      _selectedReminderDays = RenewalItem.defaultReminderDays.toSet();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickRenewalDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _renewalDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      setState(() => _renewalDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_renewalDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a renewal date')),
      );
      return;
    }

    final reminderDays = _selectedReminderDays.toList()
      ..sort((a, b) => b.compareTo(a));

    final item = RenewalItem(
      id: _isEditMode
          ? widget.item!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _category,
      owner: _owner,
      renewalDate: _renewalDate!,
      notes: _notesController.text.trim(),
      reminderDays: reminderDays,
    );

    await StorageService.instance.save(item);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(_isEditMode);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Renewal' : 'Add Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownMenuFormField<String>(
                key: ValueKey('owner-$_owner'),
                initialSelection: _owner,
                label: const Text('Owner'),
                dropdownMenuEntries: AddItemScreen.owners
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
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Renewal Date',
                  border: OutlineInputBorder(),
                ),
                child: InkWell(
                  onTap: _pickRenewalDate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _renewalDate == null
                          ? 'Select a date'
                          : _formatDate(_renewalDate!),
                      style: TextStyle(
                        color: _renewalDate == null
                            ? Theme.of(context).hintColor
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reminders',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...AddItemScreen.orderedReminderDays.map(
                (days) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AddItemScreen.reminderOptions[days]!),
                  value: _selectedReminderDays.contains(days),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedReminderDays.add(days);
                      } else {
                        _selectedReminderDays.remove(days);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: Text(_isEditMode ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
