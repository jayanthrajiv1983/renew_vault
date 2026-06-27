import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../theme/app_spacing.dart';
import '../../utils/haptic_feedback.dart';

/// Swipe-to-reveal wrapper for list item cards with Edit, Duplicate, and
/// Delete actions.
///
/// Swipe right-to-left to reveal actions in order: **Edit**, **Duplicate**,
/// **Delete** (trailing edge). Wrap any item card as the [child].
///
/// For lists, wrap the scroll view in [SlidableAutoCloseBehavior] so only one
/// row stays open at a time:
///
/// ```dart
/// SlidableAutoCloseBehavior(
///   child: ListView.builder(
///     itemBuilder: (context, index) => ItemSlidable(
///       key: ValueKey(items[index].id),
///       onEdit: () => _edit(items[index]),
///       onDuplicate: () => _duplicate(items[index]),
///       onDelete: () => _delete(items[index]),
///       child: RenewalCard(item: items[index], onTap: () => _open(items[index])),
///     ),
///   ),
/// )
/// ```
class ItemSlidable extends StatefulWidget {
  const ItemSlidable({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    this.groupTag = 'renew_vault_items',
    this.enabled = true,
  });

  /// The item card (or any row content) revealed when not swiped.
  final Widget child;

  /// Called when the Edit action is tapped.
  final VoidCallback onEdit;

  /// Called when the Delete action is tapped.
  final VoidCallback onDelete;

  /// Called when the Duplicate action is tapped.
  final VoidCallback onDuplicate;

  /// Shared tag for [SlidableAutoCloseBehavior] — only one slidable with the
  /// same tag stays open at a time.
  final Object? groupTag;

  /// When false, swipe gestures are disabled.
  final bool enabled;

  static const double _actionExtentRatio = 0.56;

  @override
  State<ItemSlidable> createState() => _ItemSlidableState();
}

class _ItemSlidableState extends State<ItemSlidable>
    with SingleTickerProviderStateMixin {
  late final SlidableController _controller;
  ActionPaneType _previousPaneType = ActionPaneType.none;

  @override
  void initState() {
    super.initState();
    _controller = SlidableController(this);
    _controller.actionPaneType.addListener(_onActionPaneTypeChanged);
  }

  @override
  void dispose() {
    _controller.actionPaneType.removeListener(_onActionPaneTypeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onActionPaneTypeChanged() {
    final current = _controller.actionPaneType.value;
    if (_previousPaneType == ActionPaneType.none &&
        current != ActionPaneType.none) {
      AppHaptics.onSwipeOpened();
    }
    _previousPaneType = current;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final editBackground = colorScheme.primary;
    final editForeground = colorScheme.onPrimary;

    final duplicateBackground = colorScheme.surfaceContainerHighest;
    final duplicateForeground = colorScheme.onSurfaceVariant;

    final deleteBackground = colorScheme.error;
    final deleteForeground = colorScheme.onError;

    final trailingRadius = AppSpacing.cardBorderRadius;

    return Slidable(
      key: widget.key,
      controller: _controller,
      groupTag: widget.groupTag,
      enabled: widget.enabled,
      closeOnScroll: true,
      endActionPane: ActionPane(
        extentRatio: ItemSlidable._actionExtentRatio,
        motion: const StretchMotion(),
        openThreshold: 0.15,
        closeThreshold: 0.35,
        children: [
          SlidableAction(
            onPressed: (_) {
              AppHaptics.onEdit();
              widget.onEdit();
            },
            backgroundColor: editBackground,
            foregroundColor: editForeground,
            icon: Icons.edit_outlined,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) {
              AppHaptics.onDuplicate();
              widget.onDuplicate();
            },
            backgroundColor: duplicateBackground,
            foregroundColor: duplicateForeground,
            icon: Icons.copy_outlined,
            label: 'Duplicate',
          ),
          SlidableAction(
            onPressed: (_) {
              AppHaptics.onDelete();
              widget.onDelete();
            },
            backgroundColor: deleteBackground,
            foregroundColor: deleteForeground,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: BorderRadius.only(
              topRight: trailingRadius.topRight,
              bottomRight: trailingRadius.bottomRight,
            ),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}
