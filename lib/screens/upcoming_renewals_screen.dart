import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/renewal_item.dart';
import '../services/pending_delete_controller.dart';
import '../services/reminders_service.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import '../widgets/reminders_caught_up_empty_state.dart';
import '../widgets/slidable_renewal_card.dart';
import 'item_detail_screen.dart';

class UpcomingRenewalsScreen extends StatefulWidget {
  const UpcomingRenewalsScreen({super.key});

  @override
  State<UpcomingRenewalsScreen> createState() => _UpcomingRenewalsScreenState();
}

class _UpcomingRenewalsScreenState extends State<UpcomingRenewalsScreen> {
  final _reminders = RemindersService.instance;
  List<RenewalItem> _items = [];

  @override
  void initState() {
    super.initState();
    PendingDeleteController.instance.addListener(_loadItems);
    _loadItems();
  }

  @override
  void dispose() {
    PendingDeleteController.instance.removeListener(_loadItems);
    super.dispose();
  }

  void _loadItems() {
    setState(() {
      _items = _reminders.getRenewalsWithUpcomingReminders();
    });
  }

  Future<void> _openItemDetail(RenewalItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
    );
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Upcoming Items'),
      ),
      body: SafeArea(
        child: _items.isEmpty
            ? const RemindersCaughtUpEmptyState()
            : SlidableAutoCloseBehavior(
                child: ListView.builder(
                  padding: listScrollPadding(
                    context,
                    top: AppSpacing.fieldLabelGap,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return SlidableRenewalCard(
                      item: item,
                      onTap: () => _openItemDetail(item),
                      onItemChanged: _loadItems,
                    );
                  },
                ),
              ),
      ),
    );
  }
}
