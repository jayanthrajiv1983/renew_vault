import 'package:flutter/material.dart';

import '../models/renewal_item.dart';
import '../screens/item_detail_screen.dart';
import '../services/storage_service.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import '../widgets/renewal_card.dart';

class RenewalSearchDelegate extends SearchDelegate<void> {
  RenewalSearchDelegate({this.onItemChanged});

  final VoidCallback? onItemChanged;

  List<RenewalItem> _search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    final lowerQuery = trimmed.toLowerCase();
    return StorageService.instance.getAll().where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
          item.category.toLowerCase().contains(lowerQuery) ||
          item.owner.toLowerCase().contains(lowerQuery) ||
          item.notes.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<void> _openItemDetail(BuildContext context, RenewalItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
    );

    if (changed == true) {
      onItemChanged?.call();
      showSuggestions(context);
    }
  }

  Widget _buildResultsList(BuildContext context, List<RenewalItem> results) {
    if (query.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No matching renewals found',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView(
      padding: listScrollPadding(context, top: AppSpacing.fieldLabelGap),
      children: results
          .map(
            (item) => RenewalCard(
              item: item,
              onTap: () => _openItemDetail(context, item),
            ),
          )
          .toList(),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) {
      return null;
    }

    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultsList(context, _search(query));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text(
          'Search by title, category, owner, or notes',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return _buildResultsList(context, _search(query));
  }
}
