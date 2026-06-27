import '../constants/categories.dart';
import '../models/renewal_item.dart';
import '../widgets/renewal_card.dart';

class OverviewStats {
  const OverviewStats({
    required this.total,
    required this.expired,
    required this.expiringSoon,
    required this.safe,
  });

  final int total;
  final int expired;
  final int expiringSoon;
  final int safe;
}

class ExpiryTrendStats {
  const ExpiryTrendStats({
    required this.thisMonth,
    required this.nextMonth,
    required this.next3Months,
    required this.next6Months,
  });

  final int thisMonth;
  final int nextMonth;
  final int next3Months;
  final int next6Months;
}

class MonthlyExpiryBucket {
  const MonthlyExpiryBucket({
    required this.month,
    required this.label,
    required this.count,
  });

  final DateTime month;
  final String label;
  final int count;
}

class AnalyticsData {
  const AnalyticsData({
    required this.overview,
    required this.categoryCounts,
    required this.ownerCounts,
    required this.expiryTrend,
    required this.monthlyExpiries,
    required this.upcomingItems,
    required this.estimatedAnnualSpending,
    required this.itemsWithCostCount,
  });

  final OverviewStats overview;
  final Map<String, int> categoryCounts;
  final Map<String, int> ownerCounts;
  final ExpiryTrendStats expiryTrend;
  final List<MonthlyExpiryBucket> monthlyExpiries;
  final List<RenewalItem> upcomingItems;
  final double estimatedAnnualSpending;
  final int itemsWithCostCount;
}

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  static List<String> get categories => Categories.ordered;

  AnalyticsData compute(List<RenewalItem> items) {
    final spending = _computeEstimatedSpending(items);

    return AnalyticsData(
      overview: _computeOverview(items),
      categoryCounts: _computeCategoryCounts(items),
      ownerCounts: _computeOwnerCounts(items),
      expiryTrend: _computeExpiryTrend(items),
      monthlyExpiries: _computeMonthlyExpiries(items),
      upcomingItems: _computeUpcomingItems(items),
      estimatedAnnualSpending: spending.total,
      itemsWithCostCount: spending.count,
    );
  }

  OverviewStats _computeOverview(List<RenewalItem> items) {
    var expired = 0;
    var expiringSoon = 0;
    var safe = 0;

    for (final item in items) {
      final days = getDaysRemaining(item.renewalDate);
      if (days < 0) {
        expired++;
      } else if (days <= 30) {
        expiringSoon++;
      } else {
        safe++;
      }
    }

    return OverviewStats(
      total: items.length,
      expired: expired,
      expiringSoon: expiringSoon,
      safe: safe,
    );
  }

  Map<String, int> _computeCategoryCounts(List<RenewalItem> items) {
    final counts = {for (final category in categories) category: 0};

    for (final item in items) {
      if (counts.containsKey(item.category)) {
        counts[item.category] = counts[item.category]! + 1;
      } else {
        counts['Other'] = counts['Other']! + 1;
      }
    }

    return counts;
  }

  Map<String, int> _computeOwnerCounts(List<RenewalItem> items) {
    final counts = <String, int>{};

    for (final item in items) {
      final owner = item.owner.trim().isEmpty ? 'Unassigned' : item.owner;
      counts[owner] = (counts[owner] ?? 0) + 1;
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) {
          return countCompare;
        }
        return a.key.compareTo(b.key);
      });

    return Map.fromEntries(sortedEntries);
  }

  ExpiryTrendStats _computeExpiryTrend(List<RenewalItem> items) {
    final today = dateOnly(DateTime.now());
    final thisMonthEnd = DateTime(today.year, today.month + 1, 0);
    final nextMonthStart = DateTime(today.year, today.month + 1, 1);
    final nextMonthEnd = DateTime(today.year, today.month + 2, 0);
    final threeMonthCutoff = today.add(const Duration(days: 90));
    final sixMonthCutoff = today.add(const Duration(days: 180));

    var thisMonth = 0;
    var nextMonth = 0;
    var next3Months = 0;
    var next6Months = 0;

    for (final item in items) {
      final renewalDay = dateOnly(item.renewalDate);
      if (renewalDay.isBefore(today)) {
        continue;
      }

      if (!renewalDay.isAfter(thisMonthEnd)) {
        thisMonth++;
      }
      if (!renewalDay.isBefore(nextMonthStart) &&
          !renewalDay.isAfter(nextMonthEnd)) {
        nextMonth++;
      }
      if (!renewalDay.isAfter(threeMonthCutoff)) {
        next3Months++;
      }
      if (!renewalDay.isAfter(sixMonthCutoff)) {
        next6Months++;
      }
    }

    return ExpiryTrendStats(
      thisMonth: thisMonth,
      nextMonth: nextMonth,
      next3Months: next3Months,
      next6Months: next6Months,
    );
  }

  static const _monthAbbreviations = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  List<MonthlyExpiryBucket> _computeMonthlyExpiries(List<RenewalItem> items) {
    final today = dateOnly(DateTime.now());
    final currentYear = today.year;
    final buckets = <MonthlyExpiryBucket>[];

    for (var offset = 0; offset < 12; offset++) {
      final monthStart = DateTime(today.year, today.month + offset, 1);
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
      var count = 0;

      for (final item in items) {
        final renewalDay = dateOnly(item.renewalDate);
        if (renewalDay.isBefore(today)) {
          continue;
        }
        if (!renewalDay.isBefore(monthStart) && !renewalDay.isAfter(monthEnd)) {
          count++;
        }
      }

      final yearSuffix = monthStart.year != currentYear
          ? " '${monthStart.year % 100}"
          : '';
      buckets.add(
        MonthlyExpiryBucket(
          month: monthStart,
          label: '${_monthAbbreviations[monthStart.month - 1]}$yearSuffix',
          count: count,
        ),
      );
    }

    return buckets;
  }

  List<RenewalItem> _computeUpcomingItems(List<RenewalItem> items) {
    final today = dateOnly(DateTime.now());
    final upcoming = items
        .where((item) => !dateOnly(item.renewalDate).isBefore(today))
        .toList()
      ..sort((a, b) => a.renewalDate.compareTo(b.renewalDate));

    return upcoming.take(10).toList();
  }

  ({double total, int count}) _computeEstimatedSpending(List<RenewalItem> items) {
    var total = 0.0;
    var count = 0;

    for (final item in items) {
      if (!Categories.isInsuranceCategory(item.category) &&
          item.category != 'Tax') {
        continue;
      }

      final cost = _parseAnnualCost(item.metadata['annualCost']);
      if (cost != null) {
        total += cost;
        count++;
      }
    }

    return (total: total, count: count);
  }

  double? _parseAnnualCost(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final cleaned = trimmed.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }
}
