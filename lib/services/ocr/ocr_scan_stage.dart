/// Stages shown during OCR processing.
enum OcrScanStage {
  scanningImage,
  extractingText,
  classifyingDocument,
  extractingFields,
  almostDone,
  completed,
}

extension OcrScanStageLabels on OcrScanStage {
  String get message {
    switch (this) {
      case OcrScanStage.scanningImage:
        return 'Scanning image...';
      case OcrScanStage.extractingText:
        return 'Extracting text...';
      case OcrScanStage.classifyingDocument:
        return 'Classifying document...';
      case OcrScanStage.extractingFields:
        return 'Extracting fields...';
      case OcrScanStage.almostDone:
        return 'Almost done...';
      case OcrScanStage.completed:
        return 'OCR completed';
    }
  }

  /// Target overall progress (0.0–1.0) when this stage begins.
  double get progressStart {
    switch (this) {
      case OcrScanStage.scanningImage:
        return 0.0;
      case OcrScanStage.extractingText:
        return 0.15;
      case OcrScanStage.classifyingDocument:
        return 0.4;
      case OcrScanStage.extractingFields:
        return 0.65;
      case OcrScanStage.almostDone:
        return 0.88;
      case OcrScanStage.completed:
        return 1.0;
    }
  }
}

/// Progress snapshot for the OCR scanning overlay.
class OcrScanProgress {
  const OcrScanProgress({
    required this.stage,
    required this.progress,
    this.completionMessage,
  });

  const OcrScanProgress.initial()
      : stage = OcrScanStage.scanningImage,
        progress = 0,
        completionMessage = null;

  final OcrScanStage stage;
  final double progress;
  final String? completionMessage;

  String get displayMessage => completionMessage ?? stage.message;

  bool get isCompleted => stage == OcrScanStage.completed;

  OcrScanProgress copyWith({
    OcrScanStage? stage,
    double? progress,
    String? completionMessage,
  }) {
    return OcrScanProgress(
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      completionMessage: completionMessage ?? this.completionMessage,
    );
  }
}
