import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ocr_correction_service.dart';
import '../services/ocr_service.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import 'form_action_bar.dart';
import 'forms/category_form_controller.dart';
import 'forms/date_form_field.dart';
DateTime? _parseOcrDate(String value) {
  final parts = value.split('/');
  if (parts.length != 3) {
    return null;
  }
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) {
    return null;
  }
  try {
    return DateTime(year, month, day);
  } on ArgumentError {
    return null;
  }
}

String _fieldLabel(String fieldName) {
  switch (fieldName) {
    case 'documentNumber':
      return 'Document Number';
    case 'issueDate':
      return 'Issue Date';
    case 'expiryDate':
      return 'Expiry Date';
    case 'authority':
      return 'Authority';
    default:
      return fieldName;
  }
}

Future<bool?> _showOcrReviewDialog(
  BuildContext context,
  OcrEngineResult result, {
  required Map<String, String> rawOcrValues,
}) {
  final documentTypeKey = result.documentType.name;
  final hasApplicable = result.highConfidenceFields.isNotEmpty;
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        insetPadding: dialogInsetPadding(context),
        title: const Text('Scan Results'),
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.65,
          ),
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    0,
                    AppSpacing.screenPadding,
                    AppSpacing.sectionSpacing,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Detected: ${result.documentType.label}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.cardSpacing),
                      if (result.fields.isEmpty)
                        const Text('No fields were extracted from this scan.')
                      else
                        ...result.fields.map((field) {
                          final rawValue = rawOcrValues[field.fieldName];
                          final isLearned = rawValue != null &&
                              rawValue != field.extractedValue &&
                              OcrCorrectionService.instance.getSuggestion(
                                    field.fieldName,
                                    rawValue,
                                    documentType: documentTypeKey,
                                  ) ==
                                  field.extractedValue;
                          final isLow = !field.isAutoApplicable && !isLearned;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isLearned
                                      ? Icons.auto_fix_high
                                      : isLow
                                          ? Icons.warning_amber_rounded
                                          : Icons.check_circle_outline,
                                  size: 18,
                                  color: isLearned
                                      ? Theme.of(context).colorScheme.tertiary
                                      : isLow
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _fieldLabel(field.fieldName),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium,
                                      ),
                                      Text(field.extractedValue),
                                      if (isLearned && rawValue != null)
                                        Text(
                                          'Learned from prior correction (was: $rawValue)',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .tertiary,
                                              ),
                                        ),
                                      Text(
                                        '${field.confidence}% confidence'
                                        '${isLearned ? ' — learned suggestion' : isLow ? ' — verify manually' : ''}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isLow
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .error
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: AppSpacing.fieldLabelGap),
                      Text(
                        'Fields above 70% confidence will be applied (expiry date above 60%). You can edit all fields after applying.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              FormActionBar(
                primaryLabel: hasApplicable ? 'Apply' : 'OK',
                onPrimary: () => Navigator.pop(context, hasApplicable),
                onCancel: hasApplicable
                    ? () => Navigator.pop(context, false)
                    : null,
                cancelLabel: 'Cancel',
              ),
            ],
          ),
        ),
        ),
      );
    },
  );
}

void _applyOcrFields(
  CategoryFormController controller,
  OcrEngineResult result,
  Map<String, String> rawOcrValues,
  VoidCallback onChanged,
) {
  controller.clearOcrTracking();
  controller.ocrDocumentType = result.documentType.name;
  for (final field in result.highConfidenceFields) {
    final rawValue = rawOcrValues[field.fieldName] ?? field.extractedValue;
    controller.trackOcrApplied(field.fieldName, rawValue);
    switch (field.fieldName) {
      case 'documentNumber':
        controller.documentNumberController.text = field.extractedValue;
      case 'issueDate':
        controller.issueDate = _parseOcrDate(field.extractedValue);
      case 'expiryDate':
        controller.expiryDate = _parseOcrDate(field.extractedValue);
      case 'authority':
        controller.authorityController.text = field.extractedValue;
    }
  }
  onChanged();
}

class CategoryFormFields extends StatelessWidget {
  const CategoryFormFields({
    super.key,
    required this.category,
    required this.controller,
    required this.onChanged,
  });

  final String category;
  final CategoryFormController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    switch (category) {
      case 'Appliance':
        return _ApplianceFormFields(
          controller: controller,
          onChanged: onChanged,
        );
      case 'Document':
        return _DocumentFormFields(
          controller: controller,
          onChanged: onChanged,
        );
      case 'Vehicle':
        return _VehicleFormFields(
          controller: controller,
          onChanged: onChanged,
        );
      case 'Insurance':
        return _InsuranceFormFields(
          controller: controller,
          onChanged: onChanged,
        );
      case 'Tax':
        return _TaxFormFields(
          controller: controller,
          onChanged: onChanged,
        );
      case 'Other':
        return _OtherFormFields(
          controller: controller,
          onChanged: onChanged,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ApplianceFormFields extends StatelessWidget {
  const _ApplianceFormFields({
    required this.controller,
    required this.onChanged,
  });

  final CategoryFormController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller.brandController,
          decoration: const InputDecoration(
            labelText: 'Brand',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => onChanged(),
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Purchase Date',
          value: controller.purchaseDate,
          onChanged: (date) {
            controller.purchaseDate = date;
            onChanged();
          },
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Warranty Expiry',
          value: controller.warrantyExpiry,
          onChanged: (date) {
            controller.warrantyExpiry = date;
            onChanged();
          },
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'AMC Expiry',
          value: controller.amcExpiry,
          onChanged: (date) {
            controller.amcExpiry = date;
            onChanged();
          },
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Last Service Date',
          value: controller.applianceLastServiceDate,
          onChanged: (date) {
            controller.applianceLastServiceDate = date;
            onChanged();
          },
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Next Service Due',
          value: controller.nextServiceDue,
          onChanged: (date) {
            controller.nextServiceDue = date;
            onChanged();
          },
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Renewal Date',
          value: controller.renewalDate,
          required: true,
          onChanged: (date) {
            controller.renewalDate = date;
            onChanged();
          },
        ),
      ],
    );
  }
}

class _DocumentFormFields extends StatefulWidget {
  const _DocumentFormFields({
    required this.controller,
    required this.onChanged,
  });

  final CategoryFormController controller;
  final VoidCallback onChanged;

  @override
  State<_DocumentFormFields> createState() => _DocumentFormFieldsState();
}

class _DocumentFormFieldsState extends State<_DocumentFormFields> {
  bool _scanning = false;

  void _showScanningOverlay() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          elevation: 0,
          child: ColoredBox(
            color: Colors.black54,
            child: Center(
              child: Material(
                borderRadius: AppSpacing.cardBorderRadius,
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Scanning document...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _dismissScanningOverlay() {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _scanDocument() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: bottomSheetPadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) {
      return;
    }

    await widget.controller.recordAllPendingOcrCorrections();

    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image == null || !mounted) {
      return;
    }

    setState(() => _scanning = true);
    var overlayShown = false;
    try {
      if (mounted) {
        overlayShown = true;
        _showScanningOverlay();
      }

      final result = await OcrService.fastScanAndParse(image.path);

      if (overlayShown && mounted) {
        _dismissScanningOverlay();
        overlayShown = false;
      }

      if (!result.hasAnyFields) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No document fields detected. You can enter them manually.',
              ),
            ),
          );
        }
        return;
      }

      if (!mounted) {
        return;
      }

      final rawOcrValues = {
        for (final field in result.fields) field.fieldName: field.extractedValue,
      };

      final apply = await _showOcrReviewDialog(
        context,
        result,
        rawOcrValues: rawOcrValues,
      );
      if (!mounted) {
        return;
      }

      if (apply == true) {
        _applyOcrFields(
          widget.controller,
          result,
          rawOcrValues,
          widget.onChanged,
        );
      }

      if (result.lowConfidenceFields.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.highConfidenceFields.isEmpty
                  ? 'All extracted fields need manual verification. Please enter them below.'
                  : 'Please verify ${result.lowConfidenceFields.length} low-confidence field${result.lowConfidenceFields.length == 1 ? '' : 's'} manually.',
            ),
          ),
        );
      } else if (apply == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'High-confidence fields applied. Review and edit before saving.',
            ),
          ),
        );
      }
    } catch (e) {
      if (overlayShown && mounted) {
        _dismissScanningOverlay();
        overlayShown = false;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    } finally {
      if (overlayShown && mounted) {
        _dismissScanningOverlay();
      }
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _scanning ? null : _scanDocument,
          icon: _scanning
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : const Icon(Icons.document_scanner_outlined),
          label: Text(_scanning ? 'Scanning…' : 'Scan Document'),
        ),
        AppSpacing.gapField,
        TextFormField(
          controller: widget.controller.documentNumberController,
          decoration: const InputDecoration(
            labelText: 'Document Number',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) async {
            await widget.controller.recordOcrCorrectionIfChanged(
              'documentNumber',
            );
            widget.onChanged();
          },
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Issue Date',
          value: widget.controller.issueDate,
          onChanged: (date) async {
            widget.controller.issueDate = date;
            await widget.controller.recordOcrCorrectionIfChanged('issueDate');
            widget.onChanged();
          },
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Expiry Date',
          value: widget.controller.expiryDate,
          required: true,
          onChanged: (date) async {
            widget.controller.expiryDate = date;
            await widget.controller.recordOcrCorrectionIfChanged('expiryDate');
            widget.onChanged();
          },
        ),
        AppSpacing.gapField,
        TextFormField(
          controller: widget.controller.authorityController,
          decoration: const InputDecoration(
            labelText: 'Authority',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) async {
            await widget.controller.recordOcrCorrectionIfChanged('authority');
            widget.onChanged();
          },
        ),
      ],
    );
  }
}

class _VehicleFormFields extends StatelessWidget {
  const _VehicleFormFields({
    required this.controller,
    required this.onChanged,
  });

  final CategoryFormController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller.registrationNumberController,
          decoration: const InputDecoration(
            labelText: 'Registration Number',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => onChanged(),
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Insurance Expiry',
          value: controller.insuranceExpiry,
          onChanged: (date) {
            controller.insuranceExpiry = date;
            onChanged();
          },
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'PUC Expiry',
          value: controller.pucExpiry,
          onChanged: (date) {
            controller.pucExpiry = date;
            onChanged();
          },
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Last Service Date',
          value: controller.vehicleLastServiceDate,
          onChanged: (date) {
            controller.vehicleLastServiceDate = date;
            onChanged();
          },
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Renewal Date',
          value: controller.renewalDate,
          required: true,
          onChanged: (date) {
            controller.renewalDate = date;
            onChanged();
          },
        ),
      ],
    );
  }
}

class _InsuranceFormFields extends StatelessWidget {
  const _InsuranceFormFields({
    required this.controller,
    required this.onChanged,
  });

  final CategoryFormController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller.policyNumberController,
          decoration: const InputDecoration(
            labelText: 'Policy Number',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => onChanged(),
        ),
        AppSpacing.gapField,
        TextFormField(
          controller: controller.policyProviderController,
          decoration: const InputDecoration(
            labelText: 'Policy Provider',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => onChanged(),
        ),
        AppSpacing.gapField,
        TextFormField(
          controller: controller.coverageAmountController,
          decoration: const InputDecoration(
            labelText: 'Coverage Amount',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => onChanged(),
        ),
        AppSpacing.gapField,
        TextFormField(
          controller: controller.annualCostController,
          decoration: const InputDecoration(
            labelText: 'Annual Cost (optional)',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onChanged(),
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Policy Expiry',
          value: controller.policyExpiry,
          required: true,
          onChanged: (date) {
            controller.policyExpiry = date;
            onChanged();
          },
        ),
      ],
    );
  }
}

class _TaxFormFields extends StatelessWidget {
  const _TaxFormFields({
    required this.controller,
    required this.onChanged,
  });

  final CategoryFormController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller.taxTypeController,
          decoration: const InputDecoration(
            labelText: 'Tax Type',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => onChanged(),
        ),
        AppSpacing.gapField,
        TextFormField(
          controller: controller.authorityController,
          decoration: const InputDecoration(
            labelText: 'Authority',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => onChanged(),
        ),
        AppSpacing.gapField,
        TextFormField(
          controller: controller.taxAnnualCostController,
          decoration: const InputDecoration(
            labelText: 'Annual Cost (optional)',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onChanged(),
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Due Date',
          value: controller.dueDate,
          required: true,
          onChanged: (date) {
            controller.dueDate = date;
            onChanged();
          },
        ),
      ],
    );
  }
}

class _OtherFormFields extends StatelessWidget {
  const _OtherFormFields({
    required this.controller,
    required this.onChanged,
  });

  final CategoryFormController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return DateFormField(
      label: 'Renewal Date',
      value: controller.renewalDate,
      required: true,
      onChanged: (date) {
        controller.renewalDate = date;
        onChanged();
      },
    );
  }
}
