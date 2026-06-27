import 'package:flutter/material.dart';

import '../constants/categories.dart';
import '../models/renewal_item.dart';
import '../models/sort_option.dart';
import '../services/category_migration_service.dart';
import '../services/family_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/backup_flow.dart';
import '../utils/sort_helper.dart';
import '../utils/form_padding.dart';
import '../search/renewal_search_delegate.dart';
import '../widgets/renew_vault_logo.dart';
import '../widgets/renewal_card.dart';
import '../widgets/backup_reminder_banner.dart';
import '../widgets/section_header.dart';
import '../widgets/summary_stat_card.dart';
import '../widgets/create_renewal_bottom_sheet.dart';
import 'add_item_screen.dart';
import 'analytics_screen.dart';
import 'filtered_items_screen.dart';
import 'item_detail_screen.dart';
import 'settings_screen.dart';

enum HomeFilterStatus { expiringSoon, expired, safe }

/// Minimum width to show AppBar title text alongside the logo (tablet / wide).
const _kAppBarTitleBreakpoint = 600.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService.instance;
  List<RenewalItem> _items = [];

  String? _selectedCategory;
  HomeFilterStatus? _selectedStatus;
  String? _selectedOwner;
  SortOption? _explicitSort;
  bool _isRunningBackup = false;

  SortOption? get _effectiveSort =>
      SettingsService.instance.getEffectiveSortOption();

  bool get _hasActiveFilters =>
      _selectedCategory != null ||
      _selectedStatus != null ||
      _selectedOwner != null;

  @override
  void initState() {
    super.initState();
    SettingsService.instance.addListener(_onSettingsChanged);
    _applySortFromSettings();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await CategoryMigrationService.instance.runMigrationIfNeeded();
    if (mounted) {
      _loadItems();
    }
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(_applySortFromSettings);
    }
  }

  void _applySortFromSettings() {
    final saved = SettingsService.instance.getSortOption();
    _explicitSort =
        saved == null || saved == SortOption.nearestExpiry ? null : saved;
  }

  void _setExplicitSort(SortOption? option) {
    final explicit =
        option == null || option == SortOption.nearestExpiry ? null : option;
    setState(() => _explicitSort = explicit);
    SettingsService.instance.setSortOption(explicit);
  }

  Future<void> _loadItems() async {
    setState(() {
      _items = _storage.getAll();
    });
  }

  Future<void> _openAnalyticsScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AnalyticsScreen(),
      ),
    );
    _loadItems();
  }

  Future<void> _openSettingsScreen() async {
    final restored = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
    setState(_applySortFromSettings);
    if (restored == true) {
      _loadItems();
    }
  }

  Future<void> _runBackupFromHome() async {
    setState(() => _isRunningBackup = true);
    try {
      await runEncryptedBackupFlow(context);
    } finally {
      if (mounted) {
        setState(() => _isRunningBackup = false);
      }
    }
  }

  Future<void> _dismissBackupReminder() async {
    await SettingsService.instance.setBackupReminderDismissedAt(DateTime.now());
  }

  Widget? _buildBackupReminderBanner() {
    if (!SettingsService.instance.shouldShowBackupReminder()) {
      return null;
    }

    return BackupReminderBanner(
      message: SettingsService.instance.getBackupReminderMessage(),
      onBackupNow: _isRunningBackup ? null : _runBackupFromHome,
      onDismiss: _dismissBackupReminder,
    );
  }

  Future<void> _openCreateRenewal() async {
    await showCreateRenewalBottomSheet(context);
    _loadItems();
  }

  Future<void> _openItemDetail(RenewalItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
    );
    _loadItems();
  }

  Future<void> _openSearch() async {
    var needsRefresh = false;
    await showSearch(
      context: context,
      delegate: RenewalSearchDelegate(
        onItemChanged: () => needsRefresh = true,
      ),
    );
    if (needsRefresh) {
      _loadItems();
    }
  }

  Future<void> _openFilteredItems({
    required String title,
    required ItemFilter filter,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilteredItemsScreen(
          title: title,
          filter: filter,
        ),
      ),
    );
    _loadItems();
  }

  bool _matchesStatusFilter(RenewalItem item) {
    if (_selectedStatus == null) {
      return true;
    }

    final days = getDaysRemaining(item.renewalDate);
    switch (_selectedStatus!) {
      case HomeFilterStatus.expiringSoon:
        return days >= 0 && days <= 30;
      case HomeFilterStatus.expired:
        return days < 0;
      case HomeFilterStatus.safe:
        return days > 30;
    }
  }

  List<RenewalItem> _applyFilters(List<RenewalItem> items) {
    return items.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (_selectedOwner != null && item.owner != _selectedOwner) {
        return false;
      }
      if (!_matchesStatusFilter(item)) {
        return false;
      }
      return true;
    }).toList();
  }

  String _statusFilterLabel(HomeFilterStatus status) {
    switch (status) {
      case HomeFilterStatus.expiringSoon:
        return 'Expiring Soon';
      case HomeFilterStatus.expired:
        return 'Expired';
      case HomeFilterStatus.safe:
        return 'Safe';
    }
  }

  void _openFilterSheet() {
    var tempCategory = _selectedCategory;
    var tempStatus = _selectedStatus;
    var tempOwner = _selectedOwner;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: bottomSheetPadding(sheetContext),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Text(
                    'Filter Renewals',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  DropdownMenu<String?>(
                    key: ValueKey('filter-category-$tempCategory'),
                    initialSelection: tempCategory,
                    label: const Text('Category'),
                    expandedInsets: EdgeInsets.zero,
                    dropdownMenuEntries: [
                      const DropdownMenuEntry(
                        value: null,
                        label: 'All categories',
                      ),
                      ...AddItemScreen.categories.map(
                        (category) => DropdownMenuEntry(
                          value: category,
                          label: category,
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      setSheetState(() => tempCategory = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.fieldLabelGap),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: tempStatus == null,
                        onSelected: (_) {
                          setSheetState(() => tempStatus = null);
                        },
                      ),
                      FilterChip(
                        label: const Text('Expiring Soon'),
                        selected: tempStatus == HomeFilterStatus.expiringSoon,
                        onSelected: (_) {
                          setSheetState(
                            () => tempStatus = HomeFilterStatus.expiringSoon,
                          );
                        },
                      ),
                      FilterChip(
                        label: const Text('Expired'),
                        selected: tempStatus == HomeFilterStatus.expired,
                        onSelected: (_) {
                          setSheetState(
                            () => tempStatus = HomeFilterStatus.expired,
                          );
                        },
                      ),
                      FilterChip(
                        label: const Text('Safe'),
                        selected: tempStatus == HomeFilterStatus.safe,
                        onSelected: (_) {
                          setSheetState(
                            () => tempStatus = HomeFilterStatus.safe,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  DropdownMenu<String?>(
                    key: ValueKey('filter-owner-$tempOwner'),
                    initialSelection: tempOwner,
                    label: const Text('Owner'),
                    expandedInsets: EdgeInsets.zero,
                    dropdownMenuEntries: [
                      const DropdownMenuEntry(
                        value: null,
                        label: 'All owners',
                      ),
                      ...FamilyService.instance.getAll().map(
                        (member) => DropdownMenuEntry(
                          value: member.name,
                          label: member.name,
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      setSheetState(() => tempOwner = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.screenPadding),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              tempCategory = null;
                              tempStatus = null;
                              tempOwner = null;
                            });
                          },
                          child: const Text('Clear all'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.cardSpacing),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = tempCategory;
                              _selectedStatus = tempStatus;
                              _selectedOwner = tempOwner;
                            });
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _openSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: bottomSheetPadding(sheetContext),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sort Renewals',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.fieldLabelGap),
                ...SortOption.values.map(
                  (option) => RadioListTile<SortOption>(
                    title: Text(option.label),
                    value: option,
                    groupValue: _explicitSort ?? SortOption.nearestExpiry,
                    onChanged: (_) {
                      _setExplicitSort(option);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text('Clear Sorting'),
                  selected: _explicitSort == null,
                  trailing: _explicitSort == null
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    _setExplicitSort(null);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<RenewalItem> get _expiringSoon {
    final today = dateOnly(DateTime.now());
    final cutoff = today.add(const Duration(days: 30));

    final expiring = _applyFilters(_items).where((item) {
      final renewalDay = dateOnly(item.renewalDate);
      return !renewalDay.isBefore(today) && !renewalDay.isAfter(cutoff);
    }).toList();

    return sortRenewals(expiring, _effectiveSort).take(5).toList();
  }

  List<RenewalItem> get _filteredItems =>
      sortRenewals(_applyFilters(_items), _effectiveSort);

  int _countExpiringSoon() {
    return _items
        .where((item) {
          final days = getDaysRemaining(item.renewalDate);
          return days >= 0 && days <= 30;
        })
        .length;
  }

  int _countExpired() {
    return _items
        .where((item) => getDaysRemaining(item.renewalDate) < 0)
        .length;
  }

  int _countSafe() {
    return _items
        .where((item) => getDaysRemaining(item.renewalDate) > 30)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final expiringSoon = _expiringSoon;
    final filteredItems = _filteredItems;
    final expiredCount = _countExpired();

    final showAppBarTitle =
        MediaQuery.sizeOf(context).width >= _kAppBarTitleBreakpoint;

    final backupReminderBanner = _buildBackupReminderBanner();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: false,
        title: _AppBarBranding(showTitle: showAppBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Analytics',
            onPressed: _openAnalyticsScreen,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettingsScreen,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: _openSearch,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onPressed: _openSortSheet,
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filter',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadItems,
          child: _items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: listScrollPadding(context, top: AppSpacing.sectionSpacing),
                children: [
                  if (backupReminderBanner != null) backupReminderBanner,
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.65,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 80,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.38),
                            ),
                            const SizedBox(height: AppSpacing.screenPadding),
                            Text(
                              'No renewals added yet',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sectionSpacing),
                            Text(
                              'Tap the + button below to add your first renewal.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: listScrollPadding(
                  context,
                  top: 0,
                  includeFabClearance: true,
                ),
                children: [
                if (backupReminderBanner != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sectionSpacing),
                    child: backupReminderBanner,
                  ),
                if (_explicitSort != null)
                  _SortChipBar(
                    sortLabel: _explicitSort!.label,
                    onClear: () => _setExplicitSort(null),
                  ),
                if (_hasActiveFilters)
                  _ActiveFiltersBar(
                    selectedCategory: _selectedCategory,
                    selectedStatus: _selectedStatus,
                    selectedOwner: _selectedOwner,
                    statusLabel: _selectedStatus == null
                        ? null
                        : _statusFilterLabel(_selectedStatus!),
                    onClearCategory: () {
                      setState(() => _selectedCategory = null);
                    },
                    onClearStatus: () {
                      setState(() => _selectedStatus = null);
                    },
                    onClearOwner: () {
                      setState(() => _selectedOwner = null);
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sectionSpacing,
                    bottom: AppSpacing.fieldLabelGap,
                  ),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.cardSpacing,
                    crossAxisSpacing: AppSpacing.cardSpacing,
                    childAspectRatio: 1.55,
                    children: [
                      SummaryStatCard(
                        label: 'Total Items',
                        count: _items.length,
                        countColor: AppColors.statTotal(colorScheme),
                        onTap: () => _openFilteredItems(
                          title: 'Total Items',
                          filter: ItemFilter.all,
                        ),
                      ),
                      SummaryStatCard(
                        label: 'Expiring Soon',
                        count: _countExpiringSoon(),
                        countColor: AppColors.statExpiringSoon,
                        onTap: () => _openFilteredItems(
                          title: 'Expiring Soon',
                          filter: ItemFilter.expiringSoon,
                        ),
                      ),
                      SummaryStatCard(
                        label: 'Expired',
                        count: _countExpired(),
                        countColor: AppColors.statExpired,
                        onTap: () => _openFilteredItems(
                          title: 'Expired',
                          filter: ItemFilter.expired,
                        ),
                      ),
                      SummaryStatCard(
                        label: 'Safe',
                        count: _countSafe(),
                        countColor: AppColors.statSafe,
                        onTap: () => _openFilteredItems(
                          title: 'Safe',
                          filter: ItemFilter.safe,
                        ),
                      ),
                    ],
                  ),
                ),
                if (expiredCount >= 1 &&
                    SettingsService.instance.getShowExpiredBanner())
                  _OverdueAlertBanner(
                    count: expiredCount,
                    onTap: () => _openFilteredItems(
                      title: 'Expired',
                      filter: ItemFilter.expired,
                    ),
                  ),
                const SectionHeader(title: 'Expiring Soon'),
                if (expiringSoon.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.fieldLabelGap,
                    ),
                    child: Text(
                      _hasActiveFilters
                          ? 'No upcoming renewals match filters'
                          : 'No upcoming renewals',
                    ),
                  )
                else
                  ...expiringSoon.map(
                    (item) => RenewalCard(
                      item: item,
                      onTap: () => _openItemDetail(item),
                    ),
                  ),
                const SectionHeader(title: 'All Renewals'),
                if (filteredItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.fieldLabelGap,
                    ),
                    child: Text(
                      _hasActiveFilters
                          ? 'No renewals match filters'
                          : 'No renewals added yet',
                    ),
                  )
                else
                  ...filteredItems.map(
                    (item) => RenewalCard(
                      item: item,
                      onTap: () => _openItemDetail(item),
                    ),
                  ),
                ],
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateRenewal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AppBarBranding extends StatelessWidget {
  const _AppBarBranding({required this.showTitle});

  final bool showTitle;

  static const _logoSize = 36.0;

  @override
  Widget build(BuildContext context) {
    return RenewVaultLogo(
      size: _logoSize,
      showTitle: showTitle,
    );
  }
}

class _SortChipBar extends StatelessWidget {
  const _SortChipBar({
    required this.sortLabel,
    required this.onClear,
  });

  final String sortLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.cardSpacing,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          label: Text('Sort: $sortLabel'),
          onDeleted: onClear,
        ),
      ),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({
    required this.selectedCategory,
    required this.selectedStatus,
    required this.selectedOwner,
    required this.statusLabel,
    required this.onClearCategory,
    required this.onClearStatus,
    required this.onClearOwner,
  });

  final String? selectedCategory;
  final HomeFilterStatus? selectedStatus;
  final String? selectedOwner;
  final String? statusLabel;
  final VoidCallback onClearCategory;
  final VoidCallback onClearStatus;
  final VoidCallback onClearOwner;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(top: AppSpacing.cardSpacing),
      child: Row(
        children: [
          if (selectedCategory != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.fieldLabelGap),
              child: InputChip(
                label: Text('Category: $selectedCategory'),
                onDeleted: onClearCategory,
              ),
            ),
          if (selectedStatus != null && statusLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.fieldLabelGap),
              child: InputChip(
                label: Text('Status: $statusLabel'),
                onDeleted: onClearStatus,
              ),
            ),
          if (selectedOwner != null)
            InputChip(
              label: Text('Owner: $selectedOwner'),
              onDeleted: onClearOwner,
            ),
        ],
      ),
    );
  }
}

class _OverdueAlertBanner extends StatelessWidget {
  const _OverdueAlertBanner({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = count == 1
        ? 'You have 1 expired renewal'
        : 'You have $count expired renewals';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.fieldLabelGap),
      child: Material(
        color: theme.colorScheme.errorContainer,
        borderRadius: AppSpacing.cardBorderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.cardBorderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.cardSpacing,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: AppSpacing.cardSpacing),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
