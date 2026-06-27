import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/renewal_item.dart';
import '../services/pending_delete_controller.dart';
import '../services/storage_service.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import '../widgets/category_empty_state.dart';
import '../widgets/slidable_renewal_card.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

/// Lists all renewal items for a single category.
class CategoryItemsScreen extends StatefulWidget {
  const CategoryItemsScreen({
    super.key,
    required this.category,
  });

  final String category;

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
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
      _items = _storage
          .getAll()
          .where((item) => item.category == widget.category)
          .toList();
    });
  }

  Future<void> _openItemDetail(RenewalItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
    );
    _loadItems();
  }

  Future<void> _openAddItemForCategory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(
          initialCategory: widget.category,
        ),
      ),
    );
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: SafeArea(
        child: _items.isEmpty
            ? CategoryEmptyState(
                category: widget.category,
                onAddItem: _openAddItemForCategory,
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
