import 'package:flutter/material.dart';

import '../constants/categories.dart';
import '../shared/widgets/empty_state_widget.dart';

/// Empty state shown when a category has no tracked items.
class CategoryEmptyState extends StatelessWidget {
  const CategoryEmptyState({
    super.key,
    required this.category,
    required this.onAddItem,
  });

  final String category;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: EmptyStateWidget.mutedIcon(context, categoryIcon(category)),
      title: 'No items in this category',
      subtitle: 'Add an item to start tracking this category.',
      buttonText: 'Add Item',
      onButtonPressed: onAddItem,
      semanticLabel:
          'No items in this category. Add an item to start tracking this category. Add Item.',
    );
  }
}
