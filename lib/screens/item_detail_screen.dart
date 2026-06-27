import 'package:flutter/material.dart';

import '../models/renewal_item.dart';
import '../services/family_service.dart';
import '../services/storage_service.dart';
import '../theme/app_spacing.dart';
import '../utils/metadata_utils.dart';
import '../utils/form_padding.dart';
import '../constants/categories.dart';
import '../constants/reminder_intervals.dart';
import '../widgets/attachments_section.dart';
import '../widgets/item_detail_section.dart';
import '../widgets/metadata_display.dart';
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
  late final Animation<double> _basicInfoFade;
  late final Animation<Offset> _basicInfoSlide;
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
    _basicInfoFade = curved;
    _basicInfoSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(curved);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: dialogInsetPadding(context),
        title: const Text('Delete renewal?'),
        content: Text('Delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await StorageService.instance.delete(item.id);

    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String _reminderLabel(int days) {
    return ReminderIntervals.labelFor(days);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysRemaining = getDaysRemaining(item.renewalDate);
    final statusColor = getStatusColor(daysRemaining);
    final statusText = getStatusText(daysRemaining);
    final sortedReminderDays = [...item.reminderDays]..sort((a, b) => b.compareTo(a));
    final hasCategoryDetails =
        metadataForCategory(item.category, item.metadata).isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(item.title),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
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
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.screenPadding),
          FadeTransition(
            opacity: _basicInfoFade,
            child: SlideTransition(
              position: _basicInfoSlide,
              child: ItemDetailSection(
                title: 'Basic Information',
                borderRadius:
                    BorderRadius.circular(AppSpacing.sectionSpacing),
                elevation: AppSpacing.cardElevation,
                surfaceTintColor: theme.colorScheme.surfaceTint,
                trailing: _RenewalStatusBadge(daysRemaining: daysRemaining),
                child: Column(
                  children: [
                    _BasicInfoRow(
                      icon: Icons.description_outlined,
                      label: 'Title',
                      value: item.title,
                    ),
                    const Divider(height: 1),
                    _BasicInfoRow(
                      icon: categoryIcon(item.category),
                      label: 'Category',
                      value: item.category,
                    ),
                    const Divider(height: 1),
                    _BasicInfoRow(
                      icon: Icons.person_outline,
                      label: 'Owner',
                      valueWidget: _OwnerInfoValue(ownerName: item.owner),
                    ),
                    const Divider(height: 1),
                    _BasicInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Renewal Date',
                      value: formatMetadataDate(item.renewalDate),
                      valueColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasCategoryDetails)
            FadeTransition(
              opacity: _categoryDetailsFade,
              child: SlideTransition(
                position: _categoryDetailsSlide,
                child: ItemDetailSection(
                  title: 'Category Details',
                  borderRadius:
                      BorderRadius.circular(AppSpacing.sectionSpacing),
                  elevation: AppSpacing.cardElevation,
                  surfaceTintColor: theme.colorScheme.surfaceTint,
                  child: MetadataDisplay(
                    category: item.category,
                    metadata: item.metadata,
                  ),
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
              child: Text(item.notes),
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

class _BasicInfoRow extends StatelessWidget {
  const _BasicInfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    this.valueColor,
  }) : assert(value != null || valueWidget != null);

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.fieldLabelGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              icon,
              size: 18,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.cardSpacing),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.fieldLabelGap),
                Flexible(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: valueWidget ??
                        Text(
                          value!,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: valueColor ?? colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerInfoValue extends StatelessWidget {
  const _OwnerInfoValue({required this.ownerName});

  final String ownerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final member = FamilyService.instance.getByName(ownerName);
    final relationship = member?.relationship.trim() ?? '';
    final showRelationship = relationship.isNotEmpty &&
        relationship.toLowerCase() != ownerName.trim().toLowerCase();

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OwnerAvatar(ownerName: ownerName, radius: 16),
        const SizedBox(width: AppSpacing.fieldLabelGap),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ownerName,
                textAlign: TextAlign.start,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showRelationship)
                Text(
                  relationship,
                  textAlign: TextAlign.start,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
