import 'package:flutter/material.dart';

import '../core/services/logging_service.dart';
import '../models/attachment_metadata.dart';
import '../services/attachment_service.dart';

/// Full-screen in-app viewer for image attachments (decrypted before display).
class AttachmentImageViewerScreen extends StatefulWidget {
  const AttachmentImageViewerScreen({
    super.key,
    required this.attachment,
  });

  final AttachmentMetadata attachment;

  @override
  State<AttachmentImageViewerScreen> createState() =>
      _AttachmentImageViewerScreenState();
}

class _AttachmentImageViewerScreenState
    extends State<AttachmentImageViewerScreen> {
  late final Future<AttachmentViewData> _viewDataFuture;

  @override
  void initState() {
    super.initState();
    _viewDataFuture =
        AttachmentService.instance.resolveAttachmentForView(widget.attachment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.attachment.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<AttachmentViewData>(
        future: _viewDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            LoggingService.instance.logError(
              'ATTACHMENTS',
              'Viewer resolve failed attachmentId=${widget.attachment.id}',
              exception: snapshot.error,
              stackTrace: snapshot.stackTrace,
              operation: 'Image Viewer',
            );
            return _message(
              context,
              'This attachment is missing or corrupted.',
            );
          }

          final viewData = snapshot.data;
          if (viewData == null ||
              viewData.missingOrCorrupt ||
              viewData.imageBytes.isEmpty) {
            return _message(
              context,
              'This attachment is missing or corrupted.',
            );
          }

          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: Image.memory(
                viewData.imageBytes,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  LoggingService.instance.logError(
                    'ATTACHMENTS',
                    'Viewer decode failed attachmentId=${widget.attachment.id} '
                    'bytesLength=${viewData.imageBytes.length}',
                    exception: error,
                    stackTrace: stackTrace,
                    operation: 'Image Viewer',
                  );
                  return _message(
                    context,
                    'This attachment is missing or corrupted.',
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _message(BuildContext context, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
        ),
      ),
    );
  }
}
