import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'forms/category_form_controller.dart';
import 'forms/date_form_field.dart';

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

class _DocumentFormFields extends StatelessWidget {
  const _DocumentFormFields({
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
          controller: controller.documentNumberController,
          decoration: const InputDecoration(
            labelText: 'Document Number',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) async {
            await controller.recordOcrCorrectionIfChanged(
              'documentNumber',
            );
            onChanged();
          },
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Issue Date',
          value: controller.issueDate,
          onChanged: (date) async {
            controller.issueDate = date;
            await controller.recordOcrCorrectionIfChanged('issueDate');
            onChanged();
          },
        ),
        AppSpacing.gapField,
        DateFormField(
          label: 'Expiry Date',
          value: controller.expiryDate,
          required: true,
          onChanged: (date) async {
            controller.expiryDate = date;
            await controller.recordOcrCorrectionIfChanged('expiryDate');
            onChanged();
          },
        ),
        AppSpacing.gapField,
        TextFormField(
          controller: controller.authorityController,
          decoration: const InputDecoration(
            labelText: 'Authority',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) async {
            await controller.recordOcrCorrectionIfChanged('authority');
            onChanged();
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
