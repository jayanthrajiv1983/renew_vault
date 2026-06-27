import 'package:flutter/material.dart';

import '../models/attachment_metadata.dart';
import 'attachments_panel.dart';

/// Attachments picker for add/edit renewal forms. Updates local form state only;
/// the parent screen persists metadata when the user saves.
class AttachmentFormSection extends StatelessWidget {
  const AttachmentFormSection({
    super.key,
    required this.renewalItemId,
    required this.attachments,
    required this.onAttachmentsChanged,
    this.persistedAttachmentIds = const {},
    this.onPersistedAttachmentRemoved,
    this.isPremium = false,
  });

  final String renewalItemId;
  final List<AttachmentMetadata> attachments;
  final ValueChanged<List<AttachmentMetadata>> onAttachmentsChanged;
  final Set<String> persistedAttachmentIds;
  final ValueChanged<AttachmentMetadata>? onPersistedAttachmentRemoved;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return AttachmentsPanel.form(
      renewalItemId: renewalItemId,
      attachments: attachments,
      onAttachmentsChanged: onAttachmentsChanged,
      persistedAttachmentIds: persistedAttachmentIds,
      onPersistedAttachmentRemoved: onPersistedAttachmentRemoved,
      isPremium: isPremium,
    );
  }
}
