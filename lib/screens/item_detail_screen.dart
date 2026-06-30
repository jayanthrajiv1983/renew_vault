import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/renewal_item.dart';
import '../services/family_service.dart';
import '../core/theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../utils/category_fields_builder.dart';
import '../utils/form_padding.dart';
import '../utils/item_actions.dart';
import '../utils/metadata_utils.dart';
import '../constants/categories.dart';
import '../constants/reminder_intervals.dart';
import '../shared/widgets/category_details_card.dart';
import '../widgets/attachments_section.dart';
import '../widgets/item_detail_section.dart';
import '../widgets/owner_avatar.dart';
import '../widgets/renewal_card.dart';
import 'add_item_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final RenewalItem item;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _headerFade;
  late final Animation<double> _headerScale;
  late final Animation<double> _categoryDetailsFade;
  late final Animation<Offset> _categoryDetailsSlide;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    final curved = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _headerFade = curved;
    _headerScale = Tween<double>(begin: 0.92, end: 1).animate(curved);
    _categoryDetailsFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.12, 1, curve: Curves.easeOut),
    );
    _categoryDetailsSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_categoryDetailsFade);
    _contentFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  RenewalItem get item => widget.item;

  Future<void> _openEditScreen(BuildContext context) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(item: item),
      ),
    );

    if (updated == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    await ItemActions.confirmDelete(
      context,
      item,
      onDeleted: () {
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      },
    );
  }

  String _reminderLabel(int days) {
    return ReminderIntervals.labelFor(days);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = AppTextStyles.of(context);
    final daysRemaining = getDaysRemaining(item.renewalDate);
    final statusColor = getStatusColor(daysRemaining, theme.colorScheme);
    final statusText = getStatusText(daysRemaining);
    final sortedReminderDays = [...item.reminderDays]..sort((a, b) => b.compareTo(a));
    final categoryFields = categoryFieldsFor(item.category, item.metadata);
    final hasCategoryDetails = categoryFields.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => _openEditScreen(context),
            child: const Text('Edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: listScrollPadding(context),
          children: [
          FadeTransition(
            opacity: _headerFade,
            child: ScaleTransition(
              scale: _headerScale,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      categoryIcon(item.category),
                      size: 54,
                      color: categoryColor(item.category, theme.colorScheme),
                    ),
                    const SizedBox(height: AppSpacing.fieldLabelGap),
                    Text(
                      item.category,
                      textAlign: TextAlign.center,
                      style: textStyles.categoryText(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.cardSpacing),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.cardSpacing,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: AppSpacing.buttonBorderRadius,
                      ),
                      child: Text(
                        statusText,
                        style: textStyles.daysLeft(
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.screenPadding),
          ItemDetailSection(
            title: 'Basic Information',
            borderRadius: BorderRadius.circular(AppSpacing.sectionSpacing),
            elevation: AppSpacing.cardElevation,
            surfaceTintColor: theme.colorScheme.surfaceTint,
            trailing: _RenewalStatusBadge(daysRemaining: daysRemaining),
            child: Column(
              children: [
                _StaggeredFadeIn(
                  index: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DetailInfoRow(
                        icon: Icons.description_outlined,
                        label: 'Title',
                        value: item.title,
                      ),
                      const _DetailInfoDivider(),
                    ],
                  ),
                ),
                _StaggeredFadeIn(
                  index: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DetailInfoRow(
                        icon: categoryIcon(item.category),
                        label: 'Category',
                        value: item.category,
                      ),
                      const _DetailInfoDivider(),
                    ],
                  ),
                ),
                _StaggeredFadeIn(
                  index: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DetailInfoRow(
                        leading:
                            OwnerAvatar(ownerName: item.owner, radius: 20),
                        label: 'Owner',
                        valueWidget: _OwnerInfoValue(ownerName: item.owner),
                      ),
                      const _DetailInfoDivider(),
                    ],
                  ),
                ),
                _StaggeredFadeIn(
                  index: 3,
                  child: _DetailInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Expiry Date',
                    value: formatMetadataDate(item.renewalDate),
                    valueColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (hasCategoryDetails)
            FadeTransition(
              opacity: _categoryDetailsFade,
              child: SlideTransition(
                position: _categoryDetailsSlide,
                child: CategoryDetailsCard(
                  fields: categoryFields,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.sectionSpacing),
                  elevation: AppSpacing.cardElevation,
                  surfaceTintColor: theme.colorScheme.surfaceTint,
                  animationIndexOffset: 4,
                ),
              ),
            ),
          AttachmentsSection(item: item),
          FadeTransition(
            opacity: _contentFade,
            child: Column(
              children: [
          ItemDetailSection(
            title: 'Reminder Settings',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final days in sortedReminderDays)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.fieldLabelGap),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.fieldLabelGap),
                        Text(_reminderLabel(days)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (item.notes.isNotEmpty)
            ItemDetailSection(
              title: 'Notes',
              child: Text(
                item.notes,
                maxLines: 20,
                overflow: TextOverflow.ellipsis,
              ),
            ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _RenewalStatusBadge extends StatelessWidget {
  const _RenewalStatusBadge({required this.daysRemaining});

  final int daysRemaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = getStatusBadgeLabel(daysRemaining);
    final color = getStatusBadgeColor(daysRemaining);
    final dot = switch (getStatusLevel(daysRemaining)) {
      RenewalStatusLevel.safe => '🟢',
      RenewalStatusLevel.expiringSoon => '🟠',
      RenewalStatusLevel.expired => '🔴',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.fieldLabelGap,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dot, style: const TextStyle(fontSize: 10, height: 1)),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggeredFadeIn extends StatefulWidget {
  const _StaggeredFadeIn({
    required this.index,
    required this.child,
  });

  static const _delayPerItem = Duration(milliseconds: 50);
  static const _duration = Duration(milliseconds: 300);

  final int index;
  final Widget child;

  @override
  State<_StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<_StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _started = false;

  bool _shouldAnimate(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.disableAnimations) {
      return false;
    }
    return !SchedulerBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: _StaggeredFadeIn._duration);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _fade = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (!_shouldAnimate(context)) {
      _controller.value = 1;
      return;
    }

    final delay = _StaggeredFadeIn._delayPerItem * widget.index;
    Future<void>.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldAnimate(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Fixed icon column + gap; divider inset = [iconColumnWidth] + [iconGap].
class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    this.icon,
    this.leading,
    required this.label,
    this.value,
    this.valueWidget,
    this.valueColor,
  })  : assert(icon != null || leading != null),
        assert(value != null || valueWidget != null);

  static const double iconColumnWidth = 44;
  static const double iconGap = AppSpacing.sectionSpacing;
  static double get dividerLeftPadding => iconColumnWidth + iconGap;

  final IconData? icon;
  final Widget? leading;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = AppTextStyles.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.cardSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeadingSlot(colorScheme),
          const SizedBox(width: iconGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textStyles.categoryText(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.gapTitleSubtitle,
                valueWidget ??
                    Text(
                      value!,
                      style: textStyles.fieldValue(
                        color: valueColor ?? colorScheme.onSurface,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingSlot(ColorScheme colorScheme) {
    if (leading != null) {
      return SizedBox(
        width: iconColumnWidth,
        height: iconColumnWidth,
        child: Center(child: leading),
      );
    }

    return SizedBox(
      width: iconColumnWidth,
      height: iconColumnWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius + 2),
        ),
        child: Icon(
          icon,
          size: 20,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _DetailInfoDivider extends StatelessWidget {
  const _DetailInfoDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: _DetailInfoRow.dividerLeftPadding),
      child: const Divider(height: 1),
    );
  }
}

class _OwnerInfoValue extends StatelessWidget {
  const _OwnerInfoValue({required this.ownerName});

  final String ownerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = AppTextStyles.of(context);
    final colorScheme = theme.colorScheme;
    final member = FamilyService.instance.getByName(ownerName);
    final relationship = member?.relationship.trim() ?? '';
    final showRelationship = relationship.isNotEmpty &&
        relationship.toLowerCase() != ownerName.trim().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ownerName,
          style: textStyles.fieldValue(
            color: colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (showRelationship)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              relationship,
              style: textStyles.metadata(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
