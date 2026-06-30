import 'package:flutter/material.dart';

import '../constants/categories.dart';
import '../models/renewal_item.dart';
import '../widgets/renewal_card.dart';
import 'analytics_service.dart';

enum InsightPriority {
  low,
  medium,
  high,
}

class InsightItem {
  const InsightItem({
    required this.message,
    required this.icon,
    this.priority = InsightPriority.medium,
  });

  final String message;
  final IconData icon;
  final InsightPriority priority;
}

class InsightsService {
  InsightsService._();

  static final InsightsService instance = InsightsService._();

  final _analytics = AnalyticsService.instance;

  List<InsightItem> generateInsights(List<RenewalItem> items) {
    if (items.isEmpty) {
      return [];
    }

    final data = _analytics.compute(items);
    final insights = <InsightItem>[];

    final urgentItem = _findNearestWithinDays(items, 7);
    if (urgentItem != null) {
      final days = getDaysRemaining(urgentItem.renewalDate);
      insights.add(
        InsightItem(
          message: _formatExpiringSoon(urgentItem.title, days),
          icon: categoryIcon(urgentItem.category),
          priority: InsightPriority.high,
        ),
      );
    }

    final thisMonthCount = data.expiryTrend.thisMonth;
    if (thisMonthCount > 0) {
      insights.add(
        InsightItem(
          message: thisMonthCount == 1
              ? 'You have 1 item expiring this month.'
              : 'You have $thisMonthCount items expiring this month.',
          icon: Icons.calendar_month_outlined,
          priority: InsightPriority.high,
        ),
      );
    }

    final topOwner = _topOwner(data.ownerCounts);
    if (topOwner != null) {
      insights.add(
        InsightItem(
          message: '${topOwner.key} has the highest number of items.',
          icon: Icons.people_outline,
          priority: InsightPriority.medium,
        ),
      );
    }

    final topCategory = _topCategoryPercentage(data.categoryCounts, items.length);
    if (topCategory != null) {
      insights.add(
        InsightItem(
          message:
              '${_pluralizeCategory(topCategory.category)} account for '
              '${topCategory.percent}% of all items.',
          icon: categoryIcon(topCategory.category),
          priority: InsightPriority.medium,
        ),
      );
    }

    if (data.itemsWithCostCount > 0 && data.estimatedAnnualSpending > 0) {
      insights.add(
        InsightItem(
          message:
              'Estimated annual expenses: '
              '${_formatCurrency(data.estimatedAnnualSpending)}.',
          icon: Icons.payments_outlined,
          priority: InsightPriority.low,
        ),
      );
    }

    insights.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return insights;
  }

  RenewalItem? _findNearestWithinDays(List<RenewalItem> items, int maxDays) {
    RenewalItem? nearest;
    var nearestDays = maxDays + 1;

    for (final item in items) {
      final days = getDaysRemaining(item.renewalDate);
      if (days >= 0 && days <= maxDays && days < nearestDays) {
        nearest = item;
        nearestDays = days;
      }
    }

    return nearest;
  }

  String _formatExpiringSoon(String title, int days) {
    if (days == 0) {
      return '$title expires today.';
    }
    if (days == 1) {
      return '$title expires in 1 day.';
    }
    return '$title expires in $days days.';
  }

  MapEntry<String, int>? _topOwner(Map<String, int> ownerCounts) {
    if (ownerCounts.length < 2) {
      return null;
    }

    final top = ownerCounts.entries.first;
    if (top.value <= 0) {
      return null;
    }
    return top;
  }

  ({String category, int percent})? _topCategoryPercentage(
    Map<String, int> categoryCounts,
    int total,
  ) {
    if (total == 0) {
      return null;
    }

    var topCategory = '';
    var topCount = 0;

    for (final entry in categoryCounts.entries) {
      if (entry.value > topCount) {
        topCategory = entry.key;
        topCount = entry.value;
      }
    }

    if (topCount == 0) {
      return null;
    }

    final percent = ((topCount / total) * 100).round();
    return (category: topCategory, percent: percent);
  }

  String _pluralizeCategory(String category) {
    switch (category) {
      case 'Document':
        return 'Documents';
      case 'Appliance':
        return 'Appliances';
      case 'Other':
        return 'Others';
      default:
        return category;
    }
  }

  String _formatCurrency(double amount) {
    final rounded = amount.round();
    final digits = rounded.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }

    final formatted = '₹${buffer.toString()}';
    return rounded < 0 ? '-$formatted' : formatted;
  }
}
