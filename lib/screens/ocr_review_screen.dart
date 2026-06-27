import 'dart:io';

import 'package:flutter/material.dart';

import '../services/ocr/ocr_engine.dart';
import '../services/ocr/ocr_extraction_result.dart';
import '../services/ocr/ocr_form_mapper.dart';
import '../services/ocr_correction_service.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import '../widgets/form_action_bar.dart';
import '../widgets/forms/category_form_controller.dart';
import '../widgets/forms/date_form_field.dart';

enum OcrReviewOutcome { confirm, retake, cancel }

/// Full-screen review of OCR results with editable fields before applying.
class OcrReviewScreen extends StatefulWidget {
  const OcrReviewScreen({
    super.key,
    required this.imagePath,
    required this.result,
    required this.initialData,
    required this.categories,
    this.hasExistingData = false,
  });

  final String imagePath;
  final OcrEngineResult result;
  final OcrReviewData initialData;
  final List<String> categories;
  final bool hasExistingData;

  @override
  State<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends State<OcrReviewScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _documentNumberController;
  late final TextEditingController _authorityController;
  late String _category;
  DateTime? _issueDate;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _titleController = TextEditingController(text: data.title);
    _documentNumberController = TextEditingController(
      text: data.documentNumber ?? '',
    );
    _authorityController = TextEditingController(text: data.authority ?? '');
    _category = data.category;
    _issueDate = data.issueDate;
    _expiryDate = data.expiryDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _documentNumberController.dispose();
    _authorityController.dispose();
    super.dispose();
  }

  OcrExtractionResult? _fieldResult(String fieldName) {
    return widget.result.fieldNamed(fieldName);
  }

  bool _isLearned(String fieldName, String displayedValue) {
    final raw = widget.initialData.rawOcrValues[fieldName];
    if (raw == null) {
      return false;
    }
    return OcrCorrectionService.instance.wasLearnedCorrection(
      OcrExtractionResult(
        fieldName: fieldName,
        extractedValue: displayedValue,
        confidence: 0,
      ),
      documentType: widget.initialData.documentTypeKey,
      rawOcrValue: raw,
    );
  }

  Widget _confidenceHint(String fieldName) {
    final field = _fieldResult(fieldName);
    if (field == null) {
      return const SizedBox.shrink();
    }
    final isLearned = _isLearned(fieldName, field.extractedValue);
    final isLow = OcrFormMapper.isLowConfidence(field) && !isLearned;
    final color = isLearned
        ? Theme.of(context).colorScheme.tertiary
        : isLow
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            isLearned
                ? Icons.auto_fix_high
                : isLow
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${field.confidence}% confidence'
              '${isLearned ? ' — learned' : isLow ? ' — verify manually' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (widget.hasExistingData) {
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace existing fields?'),
          content: const Text(
            'Applying this scan will overwrite the current form values. '
            'You can still edit everything before saving.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (overwrite != true || !mounted) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      OcrReviewData(
        title: _titleController.text.trim(),
        category: _category,
        documentNumber: _documentNumberController.text.trim().isEmpty
            ? null
            : _documentNumberController.text.trim(),
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        authority: _authorityController.text.trim().isEmpty
            ? null
            : _authorityController.text.trim(),
        documentTypeKey: widget.initialData.documentTypeKey,
        rawOcrValues: widget.initialData.rawOcrValues,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Scan'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: formBodyPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Detected: ${widget.result.documentType.label}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.cardSpacing),
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                        child: Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                'Could not load scan preview.',
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  Text(
                    'Review and edit extracted fields before applying to the form.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.cardSpacing),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  AppSpacing.gapField,
                  DropdownMenuFormField<String>(
                    key: ValueKey('ocr-category-$_category'),
                    initialSelection: _category,
                    label: const Text('Category'),
                    dropdownMenuEntries: widget.categories
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
                  AppSpacing.gapField,
                  TextFormField(
                    controller: _documentNumberController,
                    decoration: InputDecoration(
                      labelText: OcrFormMapper.fieldLabel('documentNumber'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  _confidenceHint('documentNumber'),
                  AppSpacing.gapField,
                  DateFormField(
                    label: OcrFormMapper.fieldLabel('issueDate'),
                    value: _issueDate,
                    onChanged: (date) => setState(() => _issueDate = date),
                  ),
                  _confidenceHint('issueDate'),
                  AppSpacing.gapField,
                  DateFormField(
                    label: OcrFormMapper.fieldLabel('expiryDate'),
                    value: _expiryDate,
                    onChanged: (date) => setState(() => _expiryDate = date),
                  ),
                  _confidenceHint('expiryDate'),
                  if (_category == 'Document') ...[
                    AppSpacing.gapField,
                    TextFormField(
                      controller: _authorityController,
                      decoration: InputDecoration(
                        labelText: OcrFormMapper.fieldLabel('authority'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    _confidenceHint('authority'),
                  ],
                ],
              ),
            ),
          ),
          FormActionBar(
            primaryLabel: 'Confirm & Apply',
            onPrimary: _confirm,
            onCancel: () => Navigator.pop(context, OcrReviewOutcome.retake),
            cancelLabel: 'Retake',
            secondaryStyle: FormActionSecondaryStyle.outlined,
          ),
        ],
      ),
    );
  }
}

/// Applies confirmed OCR review data to the add/edit renewal form controllers.
void applyOcrReviewToForm({
  required OcrReviewData data,
  required String currentCategory,
  required TextEditingController titleController,
  required CategoryFormController categoryController,
  required void Function(String category) onCategoryChanged,
  required VoidCallback onChanged,
}) {
  titleController.text = data.title;

  categoryController.clearOcrTracking();
  categoryController.ocrDocumentType = data.documentTypeKey;

  void track(String fieldName, String? ocrValue) {
    if (ocrValue != null && ocrValue.isNotEmpty) {
      categoryController.trackOcrApplied(fieldName, ocrValue);
    }
  }

  if (data.category != currentCategory) {
    onCategoryChanged(data.category);
  }

  switch (data.category) {
    case 'Document':
      if (data.documentNumber != null) {
        categoryController.documentNumberController.text = data.documentNumber!;
        track('documentNumber', data.rawOcrValues['documentNumber']);
      }
      categoryController.issueDate = data.issueDate;
      track('issueDate', data.rawOcrValues['issueDate']);
      categoryController.expiryDate = data.expiryDate;
      track('expiryDate', data.rawOcrValues['expiryDate']);
      if (data.authority != null) {
        categoryController.authorityController.text = data.authority!;
        track('authority', data.rawOcrValues['authority']);
      }
    case 'Vehicle':
      if (data.documentNumber != null) {
        categoryController.registrationNumberController.text =
            data.documentNumber!;
      }
      categoryController.insuranceExpiry = data.expiryDate;
      categoryController.renewalDate = data.expiryDate;
    case 'Insurance':
      if (data.documentNumber != null) {
        categoryController.policyNumberController.text = data.documentNumber!;
      }
      categoryController.policyExpiry = data.expiryDate;
    case 'Tax':
      categoryController.dueDate = data.expiryDate;
    default:
      categoryController.renewalDate = data.expiryDate ?? data.issueDate;
  }

  onChanged();
}
