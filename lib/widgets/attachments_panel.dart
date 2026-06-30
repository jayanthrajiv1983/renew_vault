import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../core/services/logging_service.dart';
import '../core/services/crashlytics_service.dart';
import '../constants/attachment_limits.dart';
import '../features/permissions/models/app_permission_type.dart';
import '../features/permissions/services/permission_education_coordinator.dart';
import '../models/attachment_metadata.dart';
import '../models/renewal_item.dart';
import '../services/attachment_service.dart';
import '../services/storage_service.dart';
import '../theme/app_spacing.dart';
import '../utils/app_snackbar.dart';
import '../utils/form_padding.dart';
import '../utils/metadata_utils.dart';
import 'cached_attachment_thumbnail.dart';
import 'item_detail_section.dart';

enum AttachmentsPanelMode { form, detail }

/// Shared attachments UI for add/edit forms and item detail.
class AttachmentsPanel extends StatefulWidget {
  const AttachmentsPanel.form({
    super.key,
    required this.renewalItemId,
    required this.attachments,
    required this.onAttachmentsChanged,
    this.persistedAttachmentIds = const {},
    this.onPersistedAttachmentRemoved,
    this.isPremium = false,
  })  : mode = AttachmentsPanelMode.form,
        item = null,
        onItemUpdated = null;

  const AttachmentsPanel.detail({
    super.key,
    required this.item,
    this.onItemUpdated,
    this.isPremium = false,
  })  : mode = AttachmentsPanelMode.detail,
        renewalItemId = null,
        attachments = null,
        onAttachmentsChanged = null,
        persistedAttachmentIds = const {},
        onPersistedAttachmentRemoved = null;

  final AttachmentsPanelMode mode;

  // Detail mode
  final RenewalItem? item;
  final ValueChanged<RenewalItem>? onItemUpdated;

  // Form mode
  final String? renewalItemId;
  final List<AttachmentMetadata>? attachments;
  final ValueChanged<List<AttachmentMetadata>>? onAttachmentsChanged;
  final Set<String> persistedAttachmentIds;
  final ValueChanged<AttachmentMetadata>? onPersistedAttachmentRemoved;

  final bool isPremium;

  @override
  State<AttachmentsPanel> createState() => _AttachmentsPanelState();
}

class _AttachmentsPanelState extends State<AttachmentsPanel> {
  RenewalItem? _detailItem;
  bool _isBusy = false;

  bool get _isDetail => widget.mode == AttachmentsPanelMode.detail;

  List<AttachmentMetadata> get _attachments =>
      _isDetail ? _detailItem!.attachments : widget.attachments!;

  String get _renewalItemId =>
      _isDetail ? _detailItem!.id : widget.renewalItemId!;

  bool get _canAdd => AttachmentService.instance.canAddAttachmentCount(
        _attachments.length,
        isPremium: widget.isPremium,
      );

  bool get _canAddOrReplace =>
      _canAdd ||
      AttachmentService.instance.shouldOfferReplace(
        _attachments.length,
        isPremium: widget.isPremium,
      );

  @override
  void initState() {
    super.initState();
    if (_isDetail) {
      _detailItem = widget.item;
    }
  }

  @override
  void didUpdateWidget(covariant AttachmentsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isDetail &&
        oldWidget.item?.id != widget.item?.id &&
        widget.item != null) {
      _detailItem = widget.item;
    }
  }

  Future<void> _refreshDetailItem() async {
    final latest = await StorageService.instance.getById(_detailItem!.id);
    if (latest != null && mounted) {
      setState(() => _detailItem = latest);
      widget.onItemUpdated?.call(latest);
    }
  }

  Future<void> _handleLimitReached() async {
    if (!mounted) {
      return;
    }
    AppSnackBar.show(
      context,
      'Free plan allows ${AttachmentLimits.maxFreeAttachments} attachment per item.',
    );
  }

  Future<bool> _confirmReplace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: dialogInsetPadding(context),
        title: const Text('Replace attachment?'),
        content: const Text(
          'Free plan allows one attachment per item. '
          'Replace the current attachment with the new file?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep existing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _removeFormAttachmentAfterSave(AttachmentMetadata existing) async {
    final isPersisted = widget.persistedAttachmentIds.contains(existing.id);
    if (isPersisted) {
      widget.onPersistedAttachmentRemoved?.call(existing);
    } else {
      await AttachmentService.instance.deleteAttachmentFileOnly(existing);
    }
  }

  Future<void> _addAttachment(
    Future<AttachmentSaveResult?> Function(
      RenewalItem item, {
      bool isPremium,
    }) picker,
  ) async {
    if (_isBusy) {
      return;
    }

    final permissionType = _permissionTypeForPicker(picker);
    if (permissionType != null) {
      final permissionOutcome = await PermissionEducationCoordinator.prepare(
        context,
        permissionType,
      );
      if (permissionOutcome != PermissionFlowOutcome.proceed || !mounted) {
        return;
      }
    }

    final needsReplace = AttachmentService.instance.shouldOfferReplace(
      _attachments.length,
      isPremium: widget.isPremium,
    );

    if (!_canAdd && !needsReplace) {
      await _handleLimitReached();
      return;
    }

    AttachmentMetadata? replaceTarget;
    var workingAttachments = _attachments;
    if (needsReplace) {
      if (!await _confirmReplace() || !mounted) {
        return;
      }
      replaceTarget = workingAttachments.first;
      workingAttachments = workingAttachments
          .where((entry) => entry.id != replaceTarget!.id)
          .toList();
    }

    setState(() => _isBusy = true);
    try {
      final stub = AttachmentService.instance.stubItemForAttachments(
        renewalItemId: _renewalItemId,
        attachments: workingAttachments,
      );
      final AttachmentSaveResult? result;
      if (replaceTarget != null && _isDetail) {
        result = await AttachmentService.instance.pickThenReplace(
          item: stub,
          replaceTarget: replaceTarget,
          picker: picker,
          isPremium: widget.isPremium,
        );
      } else {
        result = await picker(stub, isPremium: widget.isPremium);
      }

      if (result == null || !mounted) {
        return;
      }

      if (!_isDetail && replaceTarget != null) {
        await _removeFormAttachmentAfterSave(replaceTarget);
      }

      if (_isDetail) {
        await StorageService.instance.update(result.item);
        await _refreshDetailItem();
      } else {
        widget.onAttachmentsChanged!(result.item.attachments);
      }
    } on AttachmentLimitReachedException {
      await _handleLimitReached();
    } catch (error, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureAttachments,
        'Add attachment failed',
        exception: error,
        stackTrace: stack,
        operation: 'Add Failed',
      );
      if (mounted) {
        AppSnackBar.show(context, 'Could not add attachment: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  AppPermissionType? _permissionTypeForPicker(
    Future<AttachmentSaveResult?> Function(
      RenewalItem item, {
      bool isPremium,
    }) picker,
  ) {
    if (picker == AttachmentService.instance.pickFromCamera ||
        picker == AttachmentService.instance.pickFromScan) {
      return AppPermissionType.camera;
    }
    if (picker == AttachmentService.instance.pickFromGallery ||
        picker == AttachmentService.instance.pickPdf) {
      return AppPermissionType.storage;
    }
    return null;
  }

  Future<void> _openAttachment(AttachmentMetadata attachment) async {
    final result = await AttachmentService.instance.openAttachment(attachment);
    if (!mounted || result.type == ResultType.done) {
      return;
    }

    AppSnackBar.show(
      context,
      result.message.isNotEmpty
          ? result.message
          : 'Could not open attachment.',
    );
  }

  Future<void> _confirmDelete(AttachmentMetadata attachment) async {
    final isDetail = _isDetail;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: dialogInsetPadding(context),
        title: Text(isDetail ? 'Delete attachment?' : 'Remove attachment?'),
        content: Text(
          isDetail
              ? 'Delete "${attachment.fileName}"? This cannot be undone.'
              : 'Remove "${attachment.fileName}" from this item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isDetail ? 'Delete' : 'Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      if (_isDetail) {
        final updatedItem = await AttachmentService.instance.deleteAttachment(
          _detailItem!,
          attachment,
        );
        await StorageService.instance.update(updatedItem);
        await _refreshDetailItem();
      } else {
        final isPersisted =
            widget.persistedAttachmentIds.contains(attachment.id);
        if (isPersisted) {
          widget.onPersistedAttachmentRemoved?.call(attachment);
        } else {
          await AttachmentService.instance.deleteAttachmentFileOnly(attachment);
        }
        widget.onAttachmentsChanged!(
          _attachments
              .where((entry) => entry.id != attachment.id)
              .toList(),
        );
      }
    } catch (error, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureAttachments,
        'Delete attachment failed',
        exception: error,
        stackTrace: stack,
        operation: 'Delete Failed',
      );
      if (mounted) {
        AppSnackBar.show(
          context,
          isDetail
              ? 'Could not delete attachment: $error'
              : 'Could not remove attachment: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final atLimit = !_canAdd && _attachments.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_isDetail) ...[
          Text(
            'Attachments',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.fieldLabelGap),
        ],
        Wrap(
          spacing: AppSpacing.fieldLabelGap,
          runSpacing: AppSpacing.fieldLabelGap,
          children: [
            _AttachmentActionButton(
              icon: Icons.photo_camera_outlined,
              label: 'Camera',
              onPressed: _isBusy || !_canAddOrReplace
                  ? null
                  : () => _addAttachment(
                        AttachmentService.instance.pickFromCamera,
                      ),
            ),
            _AttachmentActionButton(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              onPressed: _isBusy || !_canAddOrReplace
                  ? null
                  : () => _addAttachment(
                        AttachmentService.instance.pickFromGallery,
                      ),
            ),
            _AttachmentActionButton(
              icon: Icons.document_scanner_outlined,
              label: 'Scan',
              onPressed: _isBusy || !_canAddOrReplace
                  ? null
                  : () => _addAttachment(
                        AttachmentService.instance.pickFromScan,
                      ),
            ),
            _AttachmentActionButton(
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF',
              onPressed: _isBusy || !_canAddOrReplace
                  ? null
                  : () => _addAttachment(
                        AttachmentService.instance.pickPdf,
                      ),
            ),
          ],
        ),
        if (_attachments.isEmpty) ...[
          const SizedBox(height: AppSpacing.cardSpacing),
          Text(
            _isDetail
                ? 'No attachments yet. Add a photo or PDF to keep records with this item.'
                : 'No attachments yet. Add a photo or PDF before saving.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.cardSpacing),
          for (final attachment in _attachments) ...[
            _AttachmentTile(
              attachment: attachment,
              showOpenAction: _isDetail,
              onOpen: _isDetail ? () => _openAttachment(attachment) : null,
              onDelete: () => _confirmDelete(attachment),
            ),
            if (attachment != _attachments.last) const Divider(height: 1),
          ],
        ],
        if (atLimit) ...[
          const SizedBox(height: AppSpacing.fieldLabelGap),
          Text(
            'Free plan allows ${AttachmentLimits.maxFreeAttachments} attachment. '
            'Add a new file to replace the current one.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDetail) {
      final colorScheme = Theme.of(context).colorScheme;
      return ItemDetailSection(
        title: 'Attachments',
        borderRadius: BorderRadius.circular(AppSpacing.sectionSpacing),
        elevation: AppSpacing.cardElevation,
        surfaceTintColor: colorScheme.surfaceTint,
        child: _buildContent(context),
      );
    }
    return _buildContent(context);
  }
}

class _AttachmentActionButton extends StatelessWidget {
  const _AttachmentActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.onDelete,
    this.showOpenAction = false,
    this.onOpen,
  });

  final AttachmentMetadata attachment;
  final VoidCallback onDelete;
  final bool showOpenAction;
  final VoidCallback? onOpen;

  bool get _isImage => switch (attachment.fileType) {
        AttachmentFileType.pdf => false,
        AttachmentFileType.png || AttachmentFileType.jpg => true,
      };

  IconData get _fileIcon => switch (attachment.fileType) {
        AttachmentFileType.pdf => Icons.picture_as_pdf,
        AttachmentFileType.png || AttachmentFileType.jpg => Icons.image,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _isImage
          ? CachedAttachmentThumbnail(attachment: attachment)
          : CircleAvatar(
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(
                _fileIcon,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
      title: Text(
        attachment.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        showOpenAction
            ? '${attachment.fileType.label} · ${formatMetadataDate(attachment.uploadedAt)}'
            : attachment.fileType.label,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showOpenAction)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open',
              onPressed: onOpen,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: showOpenAction ? 'Delete' : 'Remove',
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onOpen,
    );
  }
}
