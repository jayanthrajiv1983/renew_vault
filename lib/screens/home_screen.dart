import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../core/services/logging_service.dart';
import '../models/renewal_item.dart';
import '../models/sort_option.dart';
import '../services/category_migration_service.dart';
import '../services/family_service.dart';
import '../services/pending_delete_controller.dart';
import '../services/notification_navigation_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../core/theme/design_system.dart';
import '../theme/app_colors.dart';
import '../utils/backup_flow.dart';
import '../utils/sort_helper.dart';
import '../utils/form_padding.dart';
import '../search/renewal_search_delegate.dart';
import '../widgets/renew_vault_logo.dart';
import '../widgets/renewal_card.dart';
import '../widgets/slidable_renewal_card.dart';
import '../widgets/backup_reminder_banner.dart';
import '../widgets/app_review_dialog.dart';
import '../widgets/crash_reporting_consent_dialog.dart';
import '../widgets/section_header.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/hero_insight_card.dart';
import '../shared/widgets/empty_state_widget.dart';
import '../widgets/create_renewal_bottom_sheet.dart';
import '../widgets/category_empty_state.dart';
import 'add_item_screen.dart';
import 'analytics_screen.dart';
import 'category_items_screen.dart';
import 'filtered_items_screen.dart';
import 'item_detail_screen.dart';
import 'settings_screen.dart';

enum HomeFilterStatus { expiringSoon, expired, safe }

/// Minimum width to show AppBar title text alongside the logo (tablet / wide).
const _kAppBarTitleBreakpoint = 600.0;

/// Bottom inset so extended FAB does not cover list content.
const _kFabScrollClearance = 120.0;

/// Section title padding: gap is applied by the parent sliver, not the header.
const _kHomeSectionHeaderPadding =
    EdgeInsets.only(bottom: AppDesignTokens.titleToFirstCard);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService.instance;
  final _scrollController = ScrollController();
  final _screenOpenedAt = Stopwatch()..start();
  List<RenewalItem> _items = [];
  List<RenewalItem> _expiringSoonList = [];
  List<RenewalItem> _filteredItemsList = [];
  int _expiredCount = 0;
  int _expiringSoonCount = 0;
  int _safeCount = 0;

  bool _fabExtended = true;
  double _lastScrollOffset = 0;

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
    _scrollController.addListener(_onScroll);
    SettingsService.instance.addListener(_onSettingsChanged);
    PendingDeleteController.instance.addListener(_loadItems);
    _applySortFromSettings();
    _initializeData();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      LoggingService.instance.logPerf(
        'home_screen_first_frame',
        _screenOpenedAt.elapsedMilliseconds,
      );
      NotificationNavigationService.instance.consumePendingNavigation(context);
      await maybeShowCrashReportingConsentPrompt(context);
      if (!mounted) {
        return;
      }
      await maybeShowAppReviewPrompt(context);
    });
  }

  Future<void> _initializeData() async {
    await CategoryMigrationService.instance.runMigrationIfNeeded();
    if (mounted) {
      _loadItems();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    SettingsService.instance.removeListener(_onSettingsChanged);
    PendingDeleteController.instance.removeListener(_loadItems);
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final currentOffset = _scrollController.offset;
    const topThreshold = 48.0;
    const directionDelta = 4.0;

    if (currentOffset <= topThreshold) {
      if (!_fabExtended) {
        setState(() => _fabExtended = true);
      }
    } else if (currentOffset > _lastScrollOffset + directionDelta) {
      if (_fabExtended) {
        setState(() => _fabExtended = false);
      }
    } else if (currentOffset < _lastScrollOffset - directionDelta) {
      if (!_fabExtended) {
        setState(() => _fabExtended = true);
      }
    }

    _lastScrollOffset = currentOffset;
  }

  Widget _buildFloatingActionButton() {
    const tooltip = 'Add Item';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _fabExtended
          ? FloatingActionButton.extended(
              key: const ValueKey('fab-extended'),
              tooltip: tooltip,
              onPressed: _openCreateRenewal,
              icon: Icon(
                Icons.add_rounded,
                size: AppDesignTokens.iconMedium,
              ),
              label: const Text('Add Item'),
            )
          : FloatingActionButton(
              key: const ValueKey('fab-collapsed'),
              tooltip: tooltip,
              onPressed: _openCreateRenewal,
              child: Icon(
                Icons.add_rounded,
                size: AppDesignTokens.iconMedium,
              ),
            ),
    );
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
    _recomputeLists();
  }

  void _recomputeLists() {
    final filtered = _applyFilters(_items);
    _filteredItemsList = sortRenewals(filtered, _effectiveSort);

    final today = dateOnly(DateTime.now());
    final cutoff = today.add(const Duration(days: 30));
    final expiring = filtered.where((item) {
      final renewalDay = dateOnly(item.renewalDate);
      return !renewalDay.isBefore(today) && !renewalDay.isAfter(cutoff);
    }).toList();
    _expiringSoonList =
        sortRenewals(expiring, _effectiveSort).take(5).toList();

    _expiredCount = 0;
    _expiringSoonCount = 0;
    _safeCount = 0;
    for (final item in _items) {
      final days = getDaysRemaining(item.renewalDate);
      if (days < 0) {
        _expiredCount++;
      } else if (days <= 30) {
        _expiringSoonCount++;
      } else {
        _safeCount++;
      }
    }
  }

  void _setExplicitSort(SortOption? option) {
    final explicit =
        option == null || option == SortOption.nearestExpiry ? null : option;
    setState(() {
      _explicitSort = explicit;
      _recomputeLists();
    });
    SettingsService.instance.setSortOption(explicit);
  }

  Future<void> _loadItems() async {
    final stopwatch = Stopwatch()..start();
    setState(() {
      _items = _storage.getAll();
      _recomputeLists();
    });
    stopwatch.stop();
    LoggingService.instance.logPerf(
      'home_load_items',
      stopwatch.elapsedMilliseconds,
      metadata: {'count': _items.length},
    );
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

  Future<void> _openAddItemForCategory(String category) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(initialCategory: category),
      ),
    );
    _loadItems();
  }

  Future<void> _openCategoryItems(String category) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryItemsScreen(category: category),
      ),
    );
    _loadItems();
  }

  bool _isCategoryEmpty(String? category) {
    if (category == null) {
      return false;
    }
    return !_items.any((item) => item.category == category);
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
                    'Filter Items',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDesignTokens.sectionGap),
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
                  const SizedBox(height: AppDesignTokens.sectionGap),
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppDesignTokens.titleToFirstCard),
                  Wrap(
                    spacing: AppDesignTokens.space8,
                    runSpacing: AppDesignTokens.space8,
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
                  const SizedBox(height: AppDesignTokens.sectionGap),
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
                  const SizedBox(height: AppDesignTokens.pagePaddingVertical),
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
                      const SizedBox(width: AppDesignTokens.cardGap),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = tempCategory;
                              _selectedStatus = tempStatus;
                              _selectedOwner = tempOwner;
                              _recomputeLists();
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
                  'Sort Items',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppDesignTokens.titleToFirstCard),
                ...SortOption.values.map(
                  (option) => RadioListTile<SortOption>(
                    contentPadding: EdgeInsets.zero,
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
                  contentPadding: EdgeInsets.zero,
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

  List<RenewalItem> get _expiringSoon => _expiringSoonList;

  List<RenewalItem> get _filteredItems => _filteredItemsList;

  int _countExpiringSoon() => _expiringSoonCount;

  int _countExpired() => _expiredCount;

  int _countSafe() => _safeCount;

  @override
  Widget build(BuildContext context) {
    final expiringSoon = _expiringSoon;
    final filteredItems = _filteredItems;
    final expiredCount = _countExpired();
    final showCategoryEmptyState =
        _selectedCategory != null && _isCategoryEmpty(_selectedCategory);

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
          child: SlidableAutoCloseBehavior(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: _items.isEmpty
                  ? _buildEmptyStateSlivers(
                      context,
                      backupReminderBanner: backupReminderBanner,
                    )
                  : _buildContentSlivers(
                      context,
                      backupReminderBanner: backupReminderBanner,
                      expiringSoon: expiringSoon,
                      filteredItems: filteredItems,
                      expiredCount: expiredCount,
                      showCategoryEmptyState: showCategoryEmptyState,
                    ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  List<Widget> _buildEmptyStateSlivers(
    BuildContext context, {
    required Widget? backupReminderBanner,
  }) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
        AppDesignTokens.pagePaddingHorizontal,
        AppDesignTokens.pagePaddingVertical,
        AppDesignTokens.pagePaddingHorizontal,
          _kFabScrollClearance,
        ),
        sliver: SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (backupReminderBanner != null) ...[
                backupReminderBanner,
                const SizedBox(height: AppDesignTokens.sectionGap),
              ],
              Expanded(
                child: EmptyStateWidget(
                  icon: EmptyStateWidget.mutedIcon(
                    context,
                    Icons.event_note,
                  ),
                  title: 'No items yet',
                  subtitle:
                      "Start organizing your life's essentials by adding your first item.",
                  buttonText: 'Add Item',
                  onButtonPressed: _openCreateRenewal,
                  semanticLabel:
                      "No items yet. Start organizing your life's essentials by adding your first item. Add Item.",
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  SliverPadding _horizontalSliverPadding({
    required Widget sliver,
    double top = 0,
    double bottom = 0,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppDesignTokens.pagePaddingHorizontal,
        top,
        AppDesignTokens.pagePaddingHorizontal,
        bottom,
      ),
      sliver: sliver,
    );
  }

  /// Builds [HeroInsightCard] when possible. Returns null on build failure so
  /// the legacy overdue banner can serve as fallback.
  Widget? _buildHeroInsightCard(int expiredCount) {
    try {
      return HeroInsightCard(
        expiredCount: expiredCount,
        expiringSoonCount: _countExpiringSoon(),
        onReviewExpired: () => _openFilteredItems(
          title: 'Expired',
          filter: ItemFilter.expired,
        ),
        onViewUpcoming: () => _openFilteredItems(
          title: 'Expiring Soon',
          filter: ItemFilter.expiringSoon,
        ),
        onViewVault: () => _openFilteredItems(
          title: 'Total Items',
          filter: ItemFilter.all,
        ),
      );
    } catch (e, stack) {
      assert(() {
        debugPrint('HeroInsightCard failed to build: $e\n$stack');
        return true;
      }());
      return null;
    }
  }

  Widget _buildDashboardHeader({
    required BuildContext context,
    required Widget? backupReminderBanner,
    required int expiredCount,
  }) {
    final heroInsight = _buildHeroInsightCard(expiredCount);
    final showOverdueBanner = heroInsight == null &&
        expiredCount >= 1 &&
        SettingsService.instance.getShowExpiredBanner();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
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
              setState(() {
                _selectedCategory = null;
                _recomputeLists();
              });
            },
            onClearStatus: () {
              setState(() {
                _selectedStatus = null;
                _recomputeLists();
              });
            },
            onClearOwner: () {
              setState(() {
                _selectedOwner = null;
                _recomputeLists();
              });
            },
            onCategoryTap: _selectedCategory == null
                ? null
                : () => _openCategoryItems(_selectedCategory!),
          ),
        if (heroInsight != null) ...[
          heroInsight,
          const SizedBox(height: AppDesignTokens.heroToDashboard),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount =
                constraints.maxWidth >= 840 ? 4 : 2;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppDesignTokens.cardGap,
              crossAxisSpacing: AppDesignTokens.cardGap,
              // Fixed row height: title row + value + subtitle slot + padding.
              mainAxisExtent: 128,
              children: [
                DashboardStatCard(
                  type: DashboardStatType.totalItems,
                  label: 'Total Items',
                  count: _items.length,
                  animationIndex: 0,
                  onTap: () => _openFilteredItems(
                    title: 'Total Items',
                    filter: ItemFilter.all,
                  ),
                ),
                DashboardStatCard(
                  type: DashboardStatType.expiringSoon,
                  label: 'Expiring Soon',
                  count: _countExpiringSoon(),
                  subtitle: 'Requires attention',
                  animationIndex: 1,
                  onTap: () => _openFilteredItems(
                    title: 'Expiring Soon',
                    filter: ItemFilter.expiringSoon,
                  ),
                ),
                DashboardStatCard(
                  type: DashboardStatType.expired,
                  label: 'Expired',
                  count: _countExpired(),
                  animationIndex: 2,
                  onTap: () => _openFilteredItems(
                    title: 'Expired',
                    filter: ItemFilter.expired,
                  ),
                ),
                DashboardStatCard(
                  type: DashboardStatType.safe,
                  label: 'Safe',
                  count: _countSafe(),
                  subtitle: 'All good',
                  animationIndex: 3,
                  onTap: () => _openFilteredItems(
                    title: 'Safe',
                    filter: ItemFilter.safe,
                  ),
                ),
              ],
            );
          },
        ),
        if (backupReminderBanner != null) ...[
          const SizedBox(height: AppDesignTokens.sectionGap),
          backupReminderBanner,
        ],
        if (showOverdueBanner) ...[
          const SizedBox(height: AppDesignTokens.sectionGap),
          _OverdueAlertBanner(
            count: expiredCount,
            onTap: () => _openFilteredItems(
              title: 'Expired',
              filter: ItemFilter.expired,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildContentSlivers(
    BuildContext context, {
    required Widget? backupReminderBanner,
    required List<RenewalItem> expiringSoon,
    required List<RenewalItem> filteredItems,
    required int expiredCount,
    required bool showCategoryEmptyState,
  }) {
    return [
      _horizontalSliverPadding(
        top: AppDesignTokens.sectionGap,
        sliver: SliverToBoxAdapter(
          child: _buildDashboardHeader(
            context: context,
            backupReminderBanner: backupReminderBanner,
            expiredCount: expiredCount,
          ),
        ),
      ),
      if (showCategoryEmptyState)
        _horizontalSliverPadding(
          top: AppDesignTokens.sectionGap,
          bottom: _kFabScrollClearance,
          sliver: SliverToBoxAdapter(
            child: CategoryEmptyState(
              category: _selectedCategory!,
              onAddItem: () => _openAddItemForCategory(_selectedCategory!),
            ),
          ),
        )
      else ...[
        _horizontalSliverPadding(
          top: AppDesignTokens.sectionGap,
          sliver: const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Expiring Soon',
              padding: _kHomeSectionHeaderPadding,
            ),
          ),
        ),
        if (expiringSoon.isEmpty)
          _horizontalSliverPadding(
            sliver: SliverToBoxAdapter(
              child: EmptyStateWidget.compact(
                title: _hasActiveFilters
                    ? 'No upcoming items match filters'
                    : 'No upcoming items',
              ),
            ),
          )
        else
          _horizontalSliverPadding(
            sliver: SliverList.separated(
              itemCount: expiringSoon.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppDesignTokens.cardGap),
              itemBuilder: (context, index) {
                final item = expiringSoon[index];
                return SlidableRenewalCard(
                  key: ValueKey('expiring-${item.id}'),
                  item: item,
                  onTap: () => _openItemDetail(item),
                  onItemChanged: _loadItems,
                  bottomMargin: 0,
                );
              },
            ),
          ),
        _horizontalSliverPadding(
          top: AppDesignTokens.sectionGap,
          sliver: const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'All Items',
              padding: _kHomeSectionHeaderPadding,
            ),
          ),
        ),
        if (filteredItems.isEmpty)
          _horizontalSliverPadding(
            bottom: _kFabScrollClearance,
            sliver: SliverToBoxAdapter(
              child: EmptyStateWidget.compact(
                title: _hasActiveFilters
                    ? 'No items match filters'
                    : 'No items added yet',
              ),
            ),
          )
        else
          _horizontalSliverPadding(
            bottom: _kFabScrollClearance,
            sliver: SliverList.separated(
              itemCount: filteredItems.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppDesignTokens.cardGap),
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return SlidableRenewalCard(
                  key: ValueKey('all-${item.id}'),
                  item: item,
                  onTap: () => _openItemDetail(item),
                  onItemChanged: _loadItems,
                  bottomMargin: 0,
                );
              },
            ),
          ),
      ],
    ];
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
        top: AppDesignTokens.cardGap,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          label: Text(
            'Sort: $sortLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
    this.onCategoryTap,
  });

  final String? selectedCategory;
  final HomeFilterStatus? selectedStatus;
  final String? selectedOwner;
  final String? statusLabel;
  final VoidCallback onClearCategory;
  final VoidCallback onClearStatus;
  final VoidCallback onClearOwner;
  final VoidCallback? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(top: AppDesignTokens.cardGap),
      child: Row(
        children: [
          if (selectedCategory != null)
            Padding(
              padding: const EdgeInsets.only(right: AppDesignTokens.space8),
              child: InputChip(
                label: Text(
                  'Category: $selectedCategory',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: onCategoryTap,
                onDeleted: onClearCategory,
              ),
            ),
          if (selectedStatus != null && statusLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: AppDesignTokens.space8),
              child: InputChip(
                label: Text(
                  'Status: $statusLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onDeleted: onClearStatus,
              ),
            ),
          if (selectedOwner != null)
            InputChip(
              label: Text(
                'Owner: $selectedOwner',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
        ? 'You have 1 expired item'
        : 'You have $count expired items';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.space8),
      child: Material(
        color: AppColors.expiredContainer(theme.colorScheme),
        borderRadius: AppDesignTokens.radiusSmallBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDesignTokens.radiusSmallBorder,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.space16,
              vertical: AppDesignTokens.cardGap,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: AppDesignTokens.iconMedium,
                  color: AppColors.expiredOnContainer(theme.colorScheme),
                ),
                const SizedBox(width: AppDesignTokens.cardGap),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.expiredOnContainer(theme.colorScheme),
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
