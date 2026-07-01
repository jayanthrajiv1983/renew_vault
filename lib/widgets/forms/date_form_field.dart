import 'package:flutter/material.dart';

import '../../core/theme/design_system.dart';
import 'category_detail_keys.dart';

class DateFormField extends StatelessWidget {
  const DateFormField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool required;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 50)),
      lastDate: now.add(const Duration(days: 365 * 20)),
    );

    if (picked != null) {
      onChanged(DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: const OutlineInputBorder(),
      ),
      child: InkWell(
        onTap: () => _pickDate(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDesignTokens.cardGap),
          child: Text(
            value == null ? 'Select a date' : formatDisplayDate(value!),
            style: TextStyle(
              color: value == null
                  ? Theme.of(context).hintColor
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }
}
