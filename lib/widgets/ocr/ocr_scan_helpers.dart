import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/ocr/ocr_scan_stage.dart';
import '../../core/theme/design_system.dart';
import '../../theme/app_spacing.dart';
import '../../utils/form_padding.dart';

Future<ImageSource?> showOcrSourcePicker(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: bottomSheetPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Controls the staged OCR scanning overlay.
class OcrScanOverlayController {
  OcrScanOverlayController()
      : progress = ValueNotifier(const OcrScanProgress.initial());

  final ValueNotifier<OcrScanProgress> progress;

  void update(OcrScanProgress value) {
    progress.value = value;
  }

  Future<void> showCompletionAndDismiss(
    BuildContext context, {
    Duration delay = const Duration(milliseconds: 900),
  }) async {
    await Future<void>.delayed(delay);
    if (context.mounted) {
      dismiss(context);
    }
  }

  void dismiss(BuildContext context) {
    dismissOcrScanningOverlay(context);
  }
}

OcrScanOverlayController showOcrScanningOverlay(BuildContext context) {
  final controller = OcrScanOverlayController();
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        elevation: 0,
        child: ColoredBox(
          color: Colors.black54,
          child: Center(
            child: _OcrScanningOverlayContent(controller: controller),
          ),
        ),
      ),
    ),
  );
  return controller;
}

void dismissOcrScanningOverlay(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  }
}

class _OcrScanningOverlayContent extends StatefulWidget {
  const _OcrScanningOverlayContent({required this.controller});

  final OcrScanOverlayController controller;

  @override
  State<_OcrScanningOverlayContent> createState() =>
      _OcrScanningOverlayContentState();
}

class _OcrScanningOverlayContentState extends State<_OcrScanningOverlayContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressAnim;
  double _animatedProgress = 0;
  double _progressFrom = 0;
  double _progressTo = 0;
  OcrScanProgress _display = const OcrScanProgress.initial();

  @override
  void initState() {
    super.initState();
    _display = widget.controller.progress.value;
    _animatedProgress = _display.progress;
    _progressTo = _animatedProgress;
    widget.controller.progress.addListener(_onProgressChanged);
    _progressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(() {
        if (!mounted) {
          return;
        }
        setState(() {
          _animatedProgress = lerpDouble(
                _progressFrom,
                _progressTo,
                Curves.easeOutCubic.transform(_progressAnim.value),
              ) ??
              _progressTo;
        });
      });
  }

  @override
  void dispose() {
    widget.controller.progress.removeListener(_onProgressChanged);
    _progressAnim.dispose();
    super.dispose();
  }

  void _onProgressChanged() {
    final next = widget.controller.progress.value;
    _progressFrom = _animatedProgress;
    _progressTo = next.progress.clamp(0.0, 1.0);
    setState(() => _display = next);
    _progressAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = _display.isCompleted;

    return Material(
      borderRadius: AppSpacing.cardBorderRadius,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.space32,
          vertical: AppDesignTokens.space24,
        ),
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isComplete)
                Icon(
                  Icons.check_circle_outline,
                  size: 40,
                  color: theme.colorScheme.primary,
                )
              else
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: theme.colorScheme.primary,
                  ),
                ),
              const SizedBox(height: AppDesignTokens.sectionGap),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _animatedProgress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppDesignTokens.space16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _display.displayMessage,
                  key: ValueKey(_display.displayMessage),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
