import 'package:flutter/material.dart';

import '../shared/widgets/category_details_card.dart';
import '../utils/category_fields_builder.dart';

/// Displays category-specific metadata using the shared [CategoryDetailsCard].
///
/// Prefer [CategoryDetailsCard] directly when you control the surrounding
/// section chrome and entry animations.
class MetadataDisplay extends StatelessWidget {
  const MetadataDisplay({
    super.key,
    required this.category,
    required this.metadata,
    this.animateFields = true,
  });

  final String category;
  final Map<String, dynamic> metadata;
  final bool animateFields;

  @override
  Widget build(BuildContext context) {
    final fields = categoryFieldsFor(category, metadata);
    if (fields.isEmpty) {
      return Text(
        'No additional details',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    return CategoryDetailsCard(
      fields: fields,
      animateFields: animateFields,
      wrapSection: false,
    );
  }
}
