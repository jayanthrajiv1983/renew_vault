/// Attachment count limits for free vs premium tiers.
abstract final class AttachmentLimits {
  static const maxFreeAttachments = 1;

  /// Maximum attachments allowed for a renewal item.
  /// Extend with premium checks when subscription support is added.
  static int maxAttachmentsForItem({bool isPremium = false}) {
    if (isPremium) {
      return 999;
    }
    return maxFreeAttachments;
  }
}
