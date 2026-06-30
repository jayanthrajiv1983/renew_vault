import 'package:flutter/material.dart';

import '../models/renewal_item.dart';
import '../shared/widgets/item_slidable.dart';
import '../theme/app_spacing.dart';
import '../utils/item_actions.dart';
import 'renewal_card.dart';

/// [RenewalCard] wrapped with swipe actions (Edit, Duplicate, Delete).
///
/// Parent scroll views should use [SlidableAutoCloseBehavior] from
/// `package:flutter_slidable/flutter_slidable.dart`.
class SlidableRenewalCard extends StatelessWidget {
  const SlidableRenewalCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onItemChanged,
    this.bottomMargin = AppSpacing.cardSpacing,
  });

  final RenewalItem item;
  final VoidCallback onTap;
  final VoidCallback? onItemChanged;
  final double bottomMargin;

  @override
  Widget build(BuildContext context) {
    return ItemSlidable(
      key: ValueKey(item.id),
      onEdit: () => ItemActions.openEdit(
        context,
        item,
        onChanged: onItemChanged,
      ),
      onDuplicate: () => ItemActions.duplicate(
        context,
        item,
        onDuplicated: onItemChanged,
      ),
      onDelete: () => ItemActions.confirmDelete(
        context,
        item,
        onDeleted: onItemChanged,
      ),
      child: RenewalCard(
        item: item,
        onTap: onTap,
        bottomMargin: bottomMargin,
      ),
    );
  }
}
