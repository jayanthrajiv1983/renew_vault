import 'dart:typed_data';

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
  static final Map<String, Future<Uint8List>> _resolveFutures = {};

  late final Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _resolveFutures.putIfAbsent(
      widget.attachment.id,
      () async {
        final viewData = await AttachmentService.instance
            .resolveAttachmentForView(widget.attachment);
        return viewData.imageBytes;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cacheSize =
        (widget.size * MediaQuery.devicePixelRatioOf(context)).round();

    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null && bytes.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            child: Image.memory(
              bytes,
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
