import 'package:flutter/foundation.dart';

import '../../core/services/logging_service.dart';
import 'ocr_engine.dart';
import 'ocr_isolate_worker.dart';
import 'ocr_performance_metrics.dart';
import 'ocr_scan_stage.dart';

typedef OcrProgressCallback = void Function(OcrScanProgress progress);

/// Result of a full staged OCR scan with timing metadata.
class OcrScanPipelineResult {
  const OcrScanPipelineResult({
    required this.result,
    required this.metrics,
  });

  final OcrEngineResult result;
  final OcrPerformanceMetrics metrics;

  String get completionMessage => metrics.completionMessage;
}

/// Orchestrates ML Kit (main isolate) and parsing/classification (background).
abstract final class OcrScanPipeline {
  OcrScanPipeline._();

  static Future<OcrScanPipelineResult> scan(
    String path, {
    OcrProgressCallback? onProgress,
  }) async {
    final metrics = OcrPerformanceMetrics();
    final totalStopwatch = Stopwatch()..start();

    void report(OcrScanStage stage) {
      onProgress?.call(
        OcrScanProgress(stage: stage, progress: stage.progressStart),
      );
    }

    Future<void> yieldToUi() => Future<void>.delayed(Duration.zero);

    try {
      report(OcrScanStage.scanningImage);
      await yieldToUi();

      metrics.startStage('imagePrep');
      metrics.endStage('imagePrep');

      report(OcrScanStage.extractingText);
      await yieldToUi();

      metrics.startStage('textExtraction');
      final rawText = await OcrEngine.recognizeTextAtPath(path);
      metrics.endStage('textExtraction');

      report(OcrScanStage.classifyingDocument);
      await yieldToUi();

      metrics.startStage('parse');
      final parseResult = await compute(ocrIsolateParseGeneric, rawText);
      metrics.endStage('parse');

      metrics.startStage('classify');
      final classification =
          await compute(ocrIsolateClassify, parseResult.normalizedText);
      metrics.endStage('classify');

      report(OcrScanStage.extractingFields);
      await yieldToUi();

      metrics.startStage('extract');
      final fields = await compute(
        ocrIsolateExtractFields,
        OcrExtractStageInput(
          ocrText: parseResult.normalizedText,
          classification: classification,
          genericFields: parseResult.genericFields,
        ),
      );
      metrics.endStage('extract');

      report(OcrScanStage.almostDone);
      await yieldToUi();

      final engineResult = OcrEngineResult(
        rawText: parseResult.normalizedText,
        documentType: parseResult.documentType,
        fields: fields,
        classification: classification,
      );

      totalStopwatch.stop();
      metrics.totalMs = totalStopwatch.elapsedMilliseconds;

      final fieldCount = fields
          .where((field) => field.extractedValue.trim().isNotEmpty)
          .length;
      LoggingService.instance.logInfo(
        'OCR',
        'Scan completed: ${metrics.toLogMessage(
          fieldCount: fieldCount,
          documentType: classification.displayType,
        )}',
      );

      return OcrScanPipelineResult(result: engineResult, metrics: metrics);
    } catch (error, stack) {
      totalStopwatch.stop();
      metrics.totalMs = totalStopwatch.elapsedMilliseconds;
      LoggingService.instance.logError(
        'OCR',
        'Scan pipeline failed after ${metrics.totalMs}ms',
        exception: error,
        stackTrace: stack,
        operation: 'OCR Pipeline',
      );
      rethrow;
    }
  }
}
