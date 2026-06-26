import 'package:flutter/material.dart';

import '../models/renewal_item.dart';
import '../services/storage_service.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService.instance;
  List<RenewalItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _items = _storage.getAll();
    });
  }

  Future<void> _openAddItemScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddItemScreen(),
      ),
    );
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

  List<RenewalItem> get _expiringSoon {
    final today = _dateOnly(DateTime.now());
    final cutoff = today.add(const Duration(days: 30));

    return (_items
        .where((item) {
          final renewalDay = _dateOnly(item.renewalDate);
          return !renewalDay.isBefore(today) && !renewalDay.isAfter(cutoff);
        })
        .toList()
      ..sort((a, b) => a.renewalDate.compareTo(b.renewalDate)))
        .take(5)
        .toList();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int _getDaysRemaining(DateTime renewalDate) {
    return _dateOnly(renewalDate).difference(_dateOnly(DateTime.now())).inDays;
  }

  Color _getStatusColor(int daysRemaining) {
    if (daysRemaining < 0 || daysRemaining <= 7) {
      return Colors.red;
    }
    if (daysRemaining <= 30) {
      return Colors.orange;
    }
    return Colors.green;
  }

  String _getStatusText(int daysRemaining) {
    if (daysRemaining < 0) {
      final daysAgo = -daysRemaining;
      return daysAgo == 1 ? 'Expired 1 day ago' : 'Expired $daysAgo days ago';
    }
    if (daysRemaining == 0) {
      return 'Expires today';
    }
    if (daysRemaining == 1) {
      return '1 day left';
    }
    return '$daysRemaining days left';
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Appliance':
        return Icons.kitchen_outlined;
      case 'Vehicle':
        return Icons.directions_car_outlined;
      case 'Insurance':
        return Icons.shield_outlined;
      case 'Document':
        return Icons.description_outlined;
      case 'Tax':
        return Icons.receipt_long_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _buildRenewalCard(RenewalItem item) {
    final daysRemaining = _getDaysRemaining(item.renewalDate);
    final statusColor = _getStatusColor(daysRemaining);
    final statusText = _getStatusText(daysRemaining);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openItemDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _categoryIcon(item.category),
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _countExpiringSoon() {
    return _items
        .where((item) {
          final days = _getDaysRemaining(item.renewalDate);
          return days >= 0 && days <= 30;
        })
        .length;
  }

  int _countExpired() {
    return _items
        .where((item) => _getDaysRemaining(item.renewalDate) < 0)
        .length;
  }

  int _countSafe() {
    return _items
        .where((item) => _getDaysRemaining(item.renewalDate) > 30)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final expiringSoon = _expiringSoon;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RenewVault'),
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text(
                'No renewals added yet',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: [
                      _SummaryCard(
                        label: 'Total Items',
                        count: _items.length,
                      ),
                      _SummaryCard(
                        label: 'Expiring Soon',
                        count: _countExpiringSoon(),
                      ),
                      _SummaryCard(
                        label: 'Expired',
                        count: _countExpired(),
                      ),
                      _SummaryCard(
                        label: 'Safe',
                        count: _countSafe(),
                      ),
                    ],
                  ),
                ),
                _SectionHeader(title: 'Expiring Soon'),
                if (expiringSoon.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('No upcoming renewals'),
                  )
                else
                  ...expiringSoon.map(_buildRenewalCard),
                const SizedBox(height: 16),
                _SectionHeader(title: 'All Renewals'),
                ..._items.map(_buildRenewalCard),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
