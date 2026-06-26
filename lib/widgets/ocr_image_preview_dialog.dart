import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import 'form_action_bar.dart';

enum OcrImagePreviewAction { retake, apply }

/// Shows original vs OCR-preprocessed image before running ML Kit.
Future<OcrImagePreviewAction?> showOcrImagePreviewDialog(
  BuildContext context, {
  required String originalPath,
  required String processedPath,
}) {
  return showDialog<OcrImagePreviewAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _OcrImagePreviewDialog(
        originalPath: originalPath,
        processedPath: processedPath,
      );
    },
  );
}

class _OcrImagePreviewDialog extends StatefulWidget {
  const _OcrImagePreviewDialog({
    required this.originalPath,
    required this.processedPath,
  });

  final String originalPath;
  final String processedPath;

  @override
  State<_OcrImagePreviewDialog> createState() => _OcrImagePreviewDialogState();
}

class _OcrImagePreviewDialogState extends State<_OcrImagePreviewDialog> {
  var _showProcessed = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      insetPadding: dialogInsetPadding(context),
      title: const Text('Review Scan'),
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.65,
        ),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.sectionSpacing,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Compare the original photo with the enhanced version used for OCR. '
                      'Retake if the document is cut off or unreadable.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.cardSpacing),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Original'),
                          icon: Icon(Icons.photo_outlined, size: 18),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Enhanced'),
                          icon: Icon(Icons.tune_outlined, size: 18),
                        ),
                      ],
                      selected: {_showProcessed},
                      onSelectionChanged: (selection) {
                        setState(() => _showProcessed = selection.first);
                      },
                    ),
                    const SizedBox(height: AppSpacing.cardSpacing),
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                          child: _PreviewImage(
                            path: _showProcessed
                                ? widget.processedPath
                                : widget.originalPath,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.cardSpacing),
                    if (_showProcessed)
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Enhanced: cropped, deskewed, grayscale, higher contrast, sharpened.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            FormActionBar(
              primaryLabel: 'Apply & Scan',
              onPrimary: () =>
                  Navigator.pop(context, OcrImagePreviewAction.apply),
              onCancel: () =>
                  Navigator.pop(context, OcrImagePreviewAction.retake),
              cancelLabel: 'Retake',
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Padding(
            padding: AppSpacing.cardInsets,
            child: Text(
              'Could not load preview.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }
}
