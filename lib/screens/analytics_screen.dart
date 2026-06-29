import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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

  late AnalyticsData _data;
  late List<InsightItem> _insightsList;

  @override
  void initState() {
    super.initState();
    PendingDeleteController.instance.addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    PendingDeleteController.instance.removeListener(_loadData);
    super.dispose();
  }

  void _loadData() {
    final items = _storage.getAll();
    setState(() {
      _data = _analytics.compute(items);
      _insightsList = _insights.generateInsights(items);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: SlidableAutoCloseBehavior(
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: listScrollPadding(context),
            children: [
              if (_hasInsufficientData)
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.65,
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
              else ...[
              if (_insightsList.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Smart Insights',
                  padding: EdgeInsets.only(bottom: AppSpacing.fieldLabelGap),
                ),
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _insightsList.length,
                    separatorBuilder: (_, __) =>
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
                padding: EdgeInsets.only(bottom: AppSpacing.fieldLabelGap),
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
                padding: EdgeInsets.only(bottom: AppSpacing.fieldLabelGap),
              ),
              Card(
                child: Padding(
                  padding: AppSpacing.cardInsets,
                  child: CategoryPieChart(
                    categoryCounts: _data.categoryCounts,
                    onCategoryTap: _openCategoryItems,
                  ),
                ),
              ),
              AppSpacing.gapSection,
              const SectionHeader(
                title: 'Family Member Analytics',
                padding: EdgeInsets.only(bottom: AppSpacing.fieldLabelGap),
              ),
              Card(
                child: Padding(
                  padding: AppSpacing.cardInsets,
                  child: FamilyBarChart(
                    ownerCounts: _data.ownerCounts,
                  ),
                ),
              ),
              AppSpacing.gapSection,
              const SectionHeader(
                title: 'Expiry Trend',
                padding: EdgeInsets.only(bottom: AppSpacing.fieldLabelGap),
              ),
              Card(
                child: Padding(
                  padding: AppSpacing.cardInsets,
                  child: ExpiryLineChart(
                    monthlyExpiries: _data.monthlyExpiries,
                  ),
                ),
              ),
              AppSpacing.gapSection,
              const SectionHeader(
                title: 'Upcoming Actions',
                padding: EdgeInsets.only(bottom: AppSpacing.fieldLabelGap),
              ),
              if (_data.upcomingItems.isEmpty)
                Card(
                  child: Padding(
                    padding: AppSpacing.cardInsets,
                    child: EmptyStateWidget.compact(
                      title: 'No upcoming renewals',
                    ),
                  ),
                )
              else
                ..._data.upcomingItems.map(
                  (item) => SlidableRenewalCard(
                    item: item,
                    onTap: () => _openItemDetail(item),
                    onItemChanged: _loadData,
                  ),
                ),
              AppSpacing.gapSection,
              const SectionHeader(
                title: 'Expense Estimation',
                padding: EdgeInsets.only(bottom: AppSpacing.fieldLabelGap),
              ),
              Card(
                child: Padding(
                  padding: AppSpacing.cardInsets,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated annual renewal spending: '
                        '\$${_formatCurrency(_data.estimatedAnnualSpending)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
