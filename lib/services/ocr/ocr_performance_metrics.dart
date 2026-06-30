/// Timing data for a single OCR scan (metadata only, no field values).
class OcrPerformanceMetrics {
  OcrPerformanceMetrics();

  final Map<String, int> _stageMs = {};
  int totalMs = 0;

  void startStage(String name) {
    _stageStarts[name] = DateTime.now().millisecondsSinceEpoch;
  }

  void endStage(String name) {
    final start = _stageStarts.remove(name);
    if (start == null) {
      return;
    }
    _stageMs[name] = DateTime.now().millisecondsSinceEpoch - start;
  }

  int stageMs(String name) => _stageMs[name] ?? 0;

  double get totalSeconds => totalMs / 1000.0;

  String get formattedDuration {
    final seconds = totalSeconds;
    if (seconds < 10) {
      return '${seconds.toStringAsFixed(1)} seconds';
    }
    return '${seconds.round()} seconds';
  }

  String get completionMessage => 'OCR completed in $formattedDuration';

  /// Safe for [LoggingService] — counts and durations only.
  String toLogMessage({required int fieldCount, String? documentType}) {
    final parts = <String>[
      'duration=${totalMs}ms',
      'fields=$fieldCount',
      if (documentType != null) 'type=$documentType',
      if (_stageMs.isNotEmpty)
        'stages=${_stageMs.entries.map((e) => '${e.key}:${e.value}ms').join(',')}',
    ];
    return parts.join(' ');
  }

  final Map<String, int> _stageStarts = {};
}
