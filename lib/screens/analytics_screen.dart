import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../core/services/logging_service.dart';
import '../models/renewal_item.dart';
import '../services/analytics_service.dart';
import '../services/insights_service.dart';
import '../services/pending_delete_controller.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import '../shared/widgets/empty_state_widget.dart';
import '../widgets/charts/category_pie_chart.dart';
import '../widgets/charts/expiry_line_chart.dart';
import '../widgets/charts/family_bar_chart.dart';
import '../widgets/create_renewal_bottom_sheet.dart';
import '../widgets/insight_card.dart';
import '../widgets/slidable_renewal_card.dart';
import '../widgets/section_header.dart';
import '../widgets/summary_stat_card.dart';
import 'category_items_screen.dart';
import 'item_detail_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _storage = StorageService.instance;
  final _analytics = AnalyticsService.instance;
  final _insights = InsightsService.instance;
  final _screenOpenedAt = Stopwatch()..start();

  late AnalyticsData _data;
  late List<InsightItem> _insightsList;

  @override
  void initState() {
    super.initState();
    PendingDeleteController.instance.addListener(_loadData);
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LoggingService.instance.logPerf(
        'analytics_screen_first_frame',
        _screenOpenedAt.elapsedMilliseconds,
      );
    });
  }

  @override
  void dispose() {
    PendingDeleteController.instance.removeListener(_loadData);
    super.dispose();
  }

  void _loadData() {
    final stopwatch = Stopwatch()..start();
    final items = _storage.getAll();
    final data = _analytics.compute(items);
    final insights = _insights.generateInsights(items);
    stopwatch.stop();
    LoggingService.instance.logPerf(
      'analytics_compute',
      stopwatch.elapsedMilliseconds,
      metadata: {'items': items.length},
    );
    setState(() {
      _data = data;
      _insightsList = insights;
    });
  }

  Future<void> _openCreateRenewal() async {
    await showCreateRenewalBottomSheet(context);
    _loadData();
  }

  Future<void> _openItemDetail(RenewalItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
    );
    _loadData();
  }

  Future<void> _openCategoryItems(String category) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryItemsScreen(category: category),
      ),
    );
    _loadData();
  }

  bool get _hasInsufficientData => _data.overview.total == 0;

  static const _sectionTitlePadding =
      EdgeInsets.only(bottom: AppSpacing.cardSpacing);

  SliverPadding _horizontalSliverPadding({
    required Widget sliver,
    double top = 0,
    double bottom = 0,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sectionSpacing,
        top,
        AppSpacing.sectionSpacing,
        bottom,
      ),
      sliver: sliver,
    );
  }

  Widget _buildChartsAndSummary(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_insightsList.isNotEmpty) ...[
          const SectionHeader(
            title: 'Smart Insights',
            padding: _sectionTitlePadding,
          ),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _insightsList.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.cardSpacing),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 300,
                  child: InsightCard(insight: _insightsList[index]),
                );
              },
            ),
          ),
          AppSpacing.gapSection,
        ],
        const SectionHeader(
          title: 'Overview',
          padding: _sectionTitlePadding,
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.cardSpacing,
          crossAxisSpacing: AppSpacing.cardSpacing,
          childAspectRatio: 1.55,
          children: [
            SummaryStatCard(
              label: 'Total',
              count: _data.overview.total,
              countColor: AppColors.statTotal(theme.colorScheme),
            ),
            SummaryStatCard(
              label: 'Expired',
              count: _data.overview.expired,
              countColor: AppColors.statExpired,
            ),
            SummaryStatCard(
              label: 'Expiring 30 days',
              count: _data.overview.expiringSoon,
              countColor: AppColors.statExpiringSoon,
            ),
            SummaryStatCard(
              label: 'Safe',
              count: _data.overview.safe,
              countColor: AppColors.statSafe,
            ),
          ],
        ),
        AppSpacing.gapSection,
        const SectionHeader(
          title: 'Category Breakdown',
          padding: _sectionTitlePadding,
        ),
        Card(
          child: Padding(
            padding: AppSpacing.cardInsets,
            child: RepaintBoundary(
              child: CategoryPieChart(
                categoryCounts: _data.categoryCounts,
                onCategoryTap: _openCategoryItems,
              ),
            ),
          ),
        ),
        AppSpacing.gapSection,
        const SectionHeader(
          title: 'Family Member Analytics',
          padding: _sectionTitlePadding,
        ),
        Card(
          child: Padding(
            padding: AppSpacing.cardInsets,
            child: RepaintBoundary(
              child: FamilyBarChart(
                ownerCounts: _data.ownerCounts,
              ),
            ),
          ),
        ),
        AppSpacing.gapSection,
        const SectionHeader(
          title: 'Expiry Trend',
          padding: _sectionTitlePadding,
        ),
        Card(
          child: Padding(
            padding: AppSpacing.cardInsets,
            child: RepaintBoundary(
              child: ExpiryLineChart(
                monthlyExpiries: _data.monthlyExpiries,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseEstimation(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(
          title: 'Expense Estimation',
          padding: _sectionTitlePadding,
        ),
        Card(
          child: Padding(
            padding: AppSpacing.cardInsets,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated annual spending: '
                  '\$${_formatCurrency(_data.estimatedAnnualSpending)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.fieldLabelGap),
                Text(
                  _data.itemsWithCostCount == 0
                      ? 'Add annual cost on insurance and tax items to improve this estimate.'
                      : 'Based on ${_data.itemsWithCostCount} '
                          '${_data.itemsWithCostCount == 1 ? 'item' : 'items'} '
                          'with annual cost set.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContentSlivers(BuildContext context) {
    final bottomPadding = listScrollPadding(context, top: 0).bottom;

    return [
      _horizontalSliverPadding(
        top: AppSpacing.sectionSpacing,
        sliver: SliverToBoxAdapter(
          child: _buildChartsAndSummary(context),
        ),
      ),
      _horizontalSliverPadding(
        top: AppSpacing.sectionSpacing,
        sliver: const SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Upcoming Actions',
            padding: _sectionTitlePadding,
          ),
        ),
      ),
      if (_data.upcomingItems.isEmpty)
        _horizontalSliverPadding(
          sliver: SliverToBoxAdapter(
            child: Card(
              child: Padding(
                padding: AppSpacing.cardInsets,
                child: EmptyStateWidget.compact(
                  title: 'No upcoming items',
                ),
              ),
            ),
          ),
        )
      else
        _horizontalSliverPadding(
          sliver: SliverList.builder(
            itemCount: _data.upcomingItems.length,
            itemBuilder: (context, index) {
              final item = _data.upcomingItems[index];
              return SlidableRenewalCard(
                key: ValueKey('upcoming-${item.id}'),
                item: item,
                onTap: () => _openItemDetail(item),
                onItemChanged: _loadData,
              );
            },
          ),
        ),
      _horizontalSliverPadding(
        top: AppSpacing.sectionSpacing,
        bottom: bottomPadding,
        sliver: SliverToBoxAdapter(
          child: _buildExpenseEstimation(context),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: SlidableAutoCloseBehavior(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (_hasInsufficientData)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: EmptyStateWidget.mutedIcon(
                        context,
                        Icons.insights_outlined,
                      ),
                      title: 'Not enough data yet',
                      subtitle:
                          'Add and manage more items to unlock insights.',
                      buttonText: 'Add Item',
                      onButtonPressed: _openCreateRenewal,
                      semanticLabel:
                          'Not enough data yet. Add and manage more items to unlock insights. Add Item.',
                    ),
                  )
                else
                  ..._buildContentSlivers(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }
}
