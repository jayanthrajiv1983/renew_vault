import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/renewal_item.dart';
import '../services/pending_delete_controller.dart';
import '../services/storage_service.dart';
import '../shared/widgets/empty_state_widget.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import '../widgets/renewal_card.dart';
import '../widgets/slidable_renewal_card.dart';
import 'item_detail_screen.dart';

enum ItemFilter { all, expiringSoon, expired, safe }

class FilteredItemsScreen extends StatefulWidget {
  const FilteredItemsScreen({
    super.key,
    required this.title,
    required this.filter,
  });

  final String title;
  final ItemFilter filter;

  @override
  State<FilteredItemsScreen> createState() => _FilteredItemsScreenState();
}

class _FilteredItemsScreenState extends State<FilteredItemsScreen> {
  final _storage = StorageService.instance;
  List<RenewalItem> _items = [];

  @override
  void initState() {
    super.initState();
    PendingDeleteController.instance.addListener(_loadItems);
    _loadItems();
  }

  @override
  void dispose() {
    PendingDeleteController.instance.removeListener(_loadItems);
    super.dispose();
  }

  void _loadItems() {
    setState(() {
      _items = _storage.getAll().where(_matchesFilter).toList();
    });
  }

  bool _matchesFilter(RenewalItem item) {
    final days = getDaysRemaining(item.renewalDate);
    switch (widget.filter) {
      case ItemFilter.all:
        return true;
      case ItemFilter.expiringSoon:
        return days >= 0 && days <= 30;
      case ItemFilter.expired:
        return days < 0;
      case ItemFilter.safe:
        return days > 30;
    }
  }

  Future<void> _openItemDetail(RenewalItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
    );
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: _items.isEmpty
            ? EmptyStateWidget(
                icon: EmptyStateWidget.mutedIcon(context, Icons.filter_list_off),
                title: 'No items found',
                subtitle: 'Nothing in this list matches the current filter.',
                semanticLabel:
                    'No items found. Nothing in this list matches the current filter.',
              )
            : SlidableAutoCloseBehavior(
                child: ListView.builder(
                  padding: listScrollPadding(
                    context,
                    top: AppSpacing.fieldLabelGap,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return SlidableRenewalCard(
                      item: item,
                      onTap: () => _openItemDetail(item),
                      onItemChanged: _loadItems,
                    );
                  },
                ),
              ),
      ),
    );
  }
}
