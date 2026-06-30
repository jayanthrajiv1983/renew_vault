import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/renewal_item.dart';
import '../screens/item_detail_screen.dart';
import '../services/pending_delete_controller.dart';
import '../services/storage_service.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import '../shared/widgets/empty_state_widget.dart';
import '../widgets/slidable_renewal_card.dart';

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

  bool get _isDatabaseEmpty => StorageService.instance.getAll().isEmpty;

  Widget _buildEmptyDatabaseState(BuildContext context) {
    return EmptyStateWidget(
      icon: EmptyStateWidget.mutedIcon(context, Icons.manage_search),
      title: 'Nothing to search yet',
      subtitle: 'Add items to start searching across Renew Vault.',
      semanticLabel:
          'Nothing to search yet. Add items to start searching across Renew Vault.',
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return EmptyStateWidget(
      icon: EmptyStateWidget.mutedIcon(context, Icons.search_off),
      title: 'No matches found',
      subtitle: 'Try a different keyword or filter.',
      semanticLabel: 'No matches found. Try a different keyword or filter.',
    );
  }

  Widget _buildSearchHint(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Search by title, category, owner, or notes',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Text(
            'Search by title, category, owner, or notes',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 3,
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
        ),
      ),
    );
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

  Widget _buildResultsList(BuildContext context) {
    if (query.trim().isEmpty) {
      if (_isDatabaseEmpty) {
        return _buildEmptyDatabaseState(context);
      }
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: PendingDeleteController.instance,
      builder: (context, _) {
        final refreshedResults = _search(query);
        if (query.trim().isEmpty) {
          if (_isDatabaseEmpty) {
            return _buildEmptyDatabaseState(context);
          }
          return const SizedBox.shrink();
        }

        if (refreshedResults.isEmpty) {
          return _buildNoResultsState(context);
        }

        return SlidableAutoCloseBehavior(
          child: ListView.builder(
            padding: listScrollPadding(context, top: AppSpacing.fieldLabelGap),
            itemCount: refreshedResults.length,
            itemBuilder: (context, index) {
              final item = refreshedResults[index];
              return SlidableRenewalCard(
                key: ValueKey(item.id),
                item: item,
                onTap: () => _openItemDetail(context, item),
                onItemChanged: () {
                  onItemChanged?.call();
                  showSuggestions(context);
                },
              );
            },
          ),
        );
      },
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
    return _buildResultsList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      if (_isDatabaseEmpty) {
        return _buildEmptyDatabaseState(context);
      }
      return _buildSearchHint(context);
    }

    return _buildResultsList(context);
  }
}
