enum SortOption {
  nearestExpiry,
  farthestExpiry,
  alphabeticalAZ,
  alphabeticalZA,
  recentlyAdded;

  String get label {
    switch (this) {
      case SortOption.nearestExpiry:
        return 'Nearest Expiry';
      case SortOption.farthestExpiry:
        return 'Farthest Expiry';
      case SortOption.alphabeticalAZ:
        return 'Alphabetical A-Z';
      case SortOption.alphabeticalZA:
        return 'Alphabetical Z-A';
      case SortOption.recentlyAdded:
        return 'Recently Added';
    }
  }
}
