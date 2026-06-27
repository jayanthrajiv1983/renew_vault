import 'package:flutter/material.dart';

import '../models/renewal_item.dart';
import 'attachments_panel.dart';

/// Attachments section for [ItemDetailScreen] — immediate StorageService updates.
class AttachmentsSection extends StatelessWidget {
  const AttachmentsSection({
    super.key,
    required this.item,
    this.onItemUpdated,
    this.isPremium = false,
  });

  final RenewalItem item;
  final ValueChanged<RenewalItem>? onItemUpdated;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return AttachmentsPanel.detail(
      item: item,
      onItemUpdated: onItemUpdated,
      isPremium: isPremium,
    );
  }
}
