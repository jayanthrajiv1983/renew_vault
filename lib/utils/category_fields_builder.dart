import '../shared/widgets/category_details_card.dart';
import 'metadata_utils.dart';

/// Builds the ordered, non-empty [CategoryField] list for a category's metadata.
List<CategoryField> categoryFieldsFor(
  String category,
  Map<String, dynamic> metadata,
) {
  final filtered = metadataForCategory(category, metadata);
  if (filtered.isEmpty) {
    return const [];
  }

  final orderedKeys = categoryMetadataKeys[category] ?? filtered.keys.toList();
  final fields = <CategoryField>[];

  for (final key in orderedKeys) {
    final value = filtered[key];
    if (value == null) {
      continue;
    }
    if (value is String && value.trim().isEmpty) {
      continue;
    }

    fields.add(
      CategoryField(
        icon: metadataIcon(key),
        label: metadataLabel(key),
        value: formatMetadataValue(key, value),
      ),
    );
  }

  // Surface any populated keys not covered by the predefined order.
  for (final entry in filtered.entries) {
    if (orderedKeys.contains(entry.key)) {
      continue;
    }
    final value = entry.value;
    if (value is String && value.trim().isEmpty) {
      continue;
    }
    fields.add(
      CategoryField(
        icon: metadataIcon(entry.key),
        label: metadataLabel(entry.key),
        value: formatMetadataValue(entry.key, value),
      ),
    );
  }

  return fields;
}

/// Returns true when at least one category detail field would be shown.
bool hasCategoryFields(String category, Map<String, dynamic> metadata) {
  return categoryFieldsFor(category, metadata).isNotEmpty;
}
