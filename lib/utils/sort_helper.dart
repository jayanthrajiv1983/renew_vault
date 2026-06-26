import '../models/renewal_item.dart';
import '../models/sort_option.dart';

/// Returns items in insertion order (newest first by id timestamp).
List<RenewalItem> naturalOrder(List<RenewalItem> items) {
  final ordered = List<RenewalItem>.from(items);
  ordered.sort((a, b) {
    final aMs = int.tryParse(a.id) ?? 0;
    final bMs = int.tryParse(b.id) ?? 0;
    return bMs.compareTo(aMs);
  });
  return ordered;
}

List<RenewalItem> sortRenewals(List<RenewalItem> items, SortOption? option) {
  if (option == null) {
    return naturalOrder(items);
  }

  final sorted = List<RenewalItem>.from(items);

  switch (option) {
    case SortOption.nearestExpiry:
      sorted.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
    case SortOption.farthestExpiry:
      sorted.sort((a, b) => b.renewalDate.compareTo(a.renewalDate));
    case SortOption.alphabeticalAZ:
      sorted.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    case SortOption.alphabeticalZA:
      sorted.sort(
        (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
      );
    case SortOption.recentlyAdded:
      sorted.sort((a, b) {
        final aMs = int.tryParse(a.id) ?? 0;
        final bMs = int.tryParse(b.id) ?? 0;
        return bMs.compareTo(aMs);
      });
  }

  return sorted;
}
