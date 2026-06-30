import 'dart:io';

import 'package:flutter/material.dart';

import '../models/attachment_metadata.dart';
import '../services/attachment_service.dart';
import '../theme/app_spacing.dart';

/// Displays a local attachment thumbnail with decoded-image caching.
///
/// Resolves the file once per attachment id and decodes at [size] logical
/// pixels via [Image.file] cacheWidth/cacheHeight (Flutter image cache).
class CachedAttachmentThumbnail extends StatefulWidget {
  const CachedAttachmentThumbnail({
    super.key,
    required this.attachment,
    this.size = 48,
  });

  final AttachmentMetadata attachment;
  final double size;

  @override
  State<CachedAttachmentThumbnail> createState() =>
      _CachedAttachmentThumbnailState();
}

class _CachedAttachmentThumbnailState extends State<CachedAttachmentThumbnail> {
  static final Map<String, Future<File>> _resolveFutures = {};

  late final Future<File> _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = _resolveFutures.putIfAbsent(
      widget.attachment.id,
      () => AttachmentService.instance.resolveAttachmentFile(widget.attachment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cacheSize =
        (widget.size * MediaQuery.devicePixelRatioOf(context)).round();

    return FutureBuilder<File>(
      future: _fileFuture,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file != null && file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            child: Image.file(
              file,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              cacheWidth: cacheSize,
              cacheHeight: cacheSize,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return _fallbackIcon(colorScheme);
              },
            ),
          );
        }
        return _fallbackIcon(colorScheme);
      },
    );
  }

  Widget _fallbackIcon(ColorScheme colorScheme) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircleAvatar(
        backgroundColor: colorScheme.secondaryContainer,
        child: Icon(
          Icons.image,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
