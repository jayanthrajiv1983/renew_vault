import 'package:flutter/material.dart';

import '../models/renewal_item.dart';
import '../services/storage_service.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import '../widgets/renewal_card.dart';
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
    _loadItems();
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
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: _items.isEmpty
            ? Center(
                child: Text(
                  'No items found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            : ListView.builder(
                padding: listScrollPadding(
                  context,
                  top: AppSpacing.fieldLabelGap,
                ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return RenewalCard(
                  item: item,
                  onTap: () => _openItemDetail(item),
                );
              },
            ),
      ),
    );
  }
}
