import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';
import '../core/theme/design_system.dart';
import '../services/ocr/ocr_engine.dart';
import '../services/ocr/ocr_extraction_result.dart';
import '../services/ocr/ocr_form_mapper.dart';
import '../services/ocr_correction_service.dart';
import '../theme/app_spacing.dart';
import '../utils/app_snackbar.dart';
import '../utils/form_padding.dart';
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

  String get _detectedDocumentType {
    final classification = widget.result.classification;
    if (classification != null) {
      return classification.displayType;
    }
    return widget.result.documentType.label;
  }

  int? get _classificationConfidencePercent {
    return widget.result.classification?.confidencePercent;
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

  bool _isFieldLowConfidence(String fieldName) {
    final field = _fieldResult(fieldName);
    if (field == null) {
      return false;
    }
    return field.isLowConfidence && !_isLearned(fieldName, field.extractedValue);
  }

  Widget _wrapLowConfidenceField(String fieldName, Widget child) {
    if (!_isFieldLowConfidence(fieldName)) {
      return child;
    }

    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final borderRadius = AppSpacing.cardBorderRadius;
    final decorationTheme = theme.inputDecorationTheme.copyWith(
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: errorColor.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
    );

    return Theme(
      data: theme.copyWith(inputDecorationTheme: decorationTheme),
      child: child,
    );
  }

  Widget _confidenceHint(String fieldName) {
    final field = _fieldResult(fieldName);
    if (field == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final isLearned = _isLearned(fieldName, field.extractedValue);
    final isLow = field.isLowConfidence && !isLearned;
    final color = isLearned
        ? theme.colorScheme.tertiary
        : isLow
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(top: AppDesignTokens.space8),
      child: Row(
        children: [
          if (isLow) ...[
            _VerifyBadge(theme: theme),
            const SizedBox(width: AppDesignTokens.space8),
          ] else if (isLearned) ...[
            Icon(Icons.auto_fix_high, size: AppDesignTokens.iconSmall - 4, color: color),
            const SizedBox(width: AppDesignTokens.space4),
          ],
          Expanded(
            child: Text(
              'Confidence: ${field.confidencePercent}%'
              '${isLearned ? ' — learned correction' : ''}',
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptAll() async {
    if (_titleController.text.trim().isEmpty) {
      AppSnackBar.show(context, 'Please enter a title');
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

  void _rescan() {
    Navigator.pop(context, OcrReviewOutcome.retake);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final classificationConfidence = _classificationConfidencePercent;
    final isClassificationLow =
        classificationConfidence != null && classificationConfidence < 60;

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
                  _DocumentDetectionCard(
                    documentType: _detectedDocumentType,
                    confidencePercent: classificationConfidence,
                    isLowConfidence: isClassificationLow,
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  _ScanPreviewCard(imagePath: widget.imagePath),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  Card(
                    child: Padding(
                      padding: AppSpacing.cardInsets,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Extracted Fields',
                            style: AppTextStyles.of(context).sectionTitle(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppDesignTokens.space4),
                          Text(
                            'Edit any value before accepting the scan.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppDesignTokens.titleToFirstCard),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              prefixIcon: Icon(Icons.title_outlined),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          AppSpacing.gapField,
                          DropdownMenuFormField<String>(
                            key: ValueKey('ocr-category-$_category'),
                            initialSelection: _category,
                            label: const Text('Category'),
                            leadingIcon: const Icon(Icons.category_outlined),
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
                          _wrapLowConfidenceField(
                            'documentNumber',
                            TextFormField(
                              controller: _documentNumberController,
                              decoration: InputDecoration(
                                labelText: OcrFormMapper.fieldLabel(
                                  'documentNumber',
                                ),
                                prefixIcon: const Icon(Icons.tag_outlined),
                              ),
                            ),
                          ),
                          _confidenceHint('documentNumber'),
                          AppSpacing.gapField,
                          _wrapLowConfidenceField(
                            'expiryDate',
                            DateFormField(
                              label: OcrFormMapper.fieldLabel('expiryDate'),
                              value: _expiryDate,
                              onChanged: (date) =>
                                  setState(() => _expiryDate = date),
                            ),
                          ),
                          _confidenceHint('expiryDate'),
                          if (_category == 'Document') ...[
                            AppSpacing.gapField,
                            _wrapLowConfidenceField(
                              'issueDate',
                              DateFormField(
                                label: OcrFormMapper.fieldLabel('issueDate'),
                                value: _issueDate,
                                onChanged: (date) =>
                                    setState(() => _issueDate = date),
                              ),
                            ),
                            _confidenceHint('issueDate'),
                            AppSpacing.gapField,
                            _wrapLowConfidenceField(
                              'authority',
                              TextFormField(
                                controller: _authorityController,
                                decoration: InputDecoration(
                                  labelText: OcrFormMapper.fieldLabel(
                                    'authority',
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.account_balance_outlined,
                                  ),
                                ),
                              ),
                            ),
                            _confidenceHint('authority'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _ReviewActionBar(
            onAcceptAll: _acceptAll,
            onRescan: _rescan,
          ),
        ],
      ),
    );
  }
}

class _DocumentDetectionCard extends StatelessWidget {
  const _DocumentDetectionCard({
    required this.documentType,
    required this.confidencePercent,
    required this.isLowConfidence,
  });

  final String documentType;
  final int? confidencePercent;
  final bool isLowConfidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: isLowConfidence
          ? colorScheme.errorContainer.withValues(alpha: 0.35)
          : colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: AppSpacing.cardInsets,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isLowConfidence
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer,
              child: Icon(
                Icons.document_scanner_outlined,
                color: isLowConfidence
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppDesignTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected Document Type',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.space4),
                  Text(
                    documentType,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (confidencePercent != null) ...[
                    const SizedBox(height: AppSpacing.cardSpacing),
                    Wrap(
                      spacing: AppDesignTokens.space8,
                      runSpacing: AppDesignTokens.space8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _ConfidenceChip(
                          label: 'Classification',
                          confidencePercent: confidencePercent!,
                          isLowConfidence: isLowConfidence,
                        ),
                        if (isLowConfidence)
                          _VerifyBadge(theme: theme),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanPreviewCard extends StatelessWidget {
  const _ScanPreviewCard({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppDesignTokens.space8),
                    Text(
                      'Could not load scan preview',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({
    required this.label,
    required this.confidencePercent,
    required this.isLowConfidence,
  });

  final String label;
  final int confidencePercent;
  final bool isLowConfidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = isLowConfidence
        ? colorScheme.errorContainer
        : colorScheme.secondaryContainer;
    final foreground = isLowConfidence
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.space8 + 2,
        vertical: AppDesignTokens.space4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(
        '$label: $confidencePercent%',
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _VerifyBadge extends StatelessWidget {
  const _VerifyBadge({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.space8,
        vertical: AppDesignTokens.space4 / 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: AppDesignTokens.iconSmall - 4,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: AppDesignTokens.space4),
          Text(
            'Verify',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewActionBar extends StatelessWidget {
  const _ReviewActionBar({
    required this.onAcceptAll,
    required this.onRescan,
  });

  final VoidCallback onAcceptAll;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: theme.colorScheme.surface,
      elevation: AppSpacing.cardElevation,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppDesignTokens.pagePaddingHorizontal,
              AppDesignTokens.cardGap,
              AppDesignTokens.pagePaddingHorizontal,
              AppDesignTokens.pagePaddingHorizontal + viewInsets,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: onAcceptAll,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Accept All'),
                ),
                const SizedBox(height: AppSpacing.fieldLabelGap),
                OutlinedButton.icon(
                  onPressed: onRescan,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Rescan'),
                ),
              ],
            ),
          ),
        ),
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
    case 'Vehicle Insurance':
      if (data.documentNumber != null) {
        categoryController.registrationNumberController.text =
            data.documentNumber!;
      }
      categoryController.insuranceExpiry = data.expiryDate;
      categoryController.renewalDate = data.expiryDate;
    case 'Health Insurance':
    case 'Life Insurance':
    case 'Travel Insurance':
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
