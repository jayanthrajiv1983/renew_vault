import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../models/app_log.dart';
import 'crashlytics_service.dart';

/// Centralized application logging backed by an unencrypted Hive box.
///
/// **Security:** Never log sensitive data — document numbers, passport or
/// policy numbers, OCR text, attachment paths, or personal information.
/// All messages are sanitized before persistence.
class LoggingService {
  static final LoggingService instance = LoggingService._internal();

  factory LoggingService() => instance;

  LoggingService._internal();

  static const _boxName = 'app_logs';
  static const _maxEntries = 500;

  static const levelInfo = 'INFO';
  static const levelWarning = 'WARNING';
  static const levelError = 'ERROR';
  static const levelDebug = 'DEBUG';

  Box<AppLog>? _box;
  int _nextKey = 0;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AppLogAdapter());
    }

    _box = await Hive.openBox<AppLog>(_boxName);
    _restoreNextKey();
    _initialized = true;
  }

  void logInfo(String category, String message) =>
      _log(levelInfo, category, message);

  void logWarning(String category, String message) =>
      _log(levelWarning, category, message);

  void logError(
    String category,
    String message, {
    Object? exception,
    StackTrace? stackTrace,
    String? operation,
  }) {
    _log(levelError, category, message);
    if (exception != null && operation != null) {
      CrashlyticsService.instance.recordFeatureError(
        feature: category,
        operation: operation,
        exception: exception,
        stackTrace: stackTrace,
      );
    } else {
      CrashlyticsService.instance.recordNonFatalFromLog(category);
    }
  }

  void logDebug(String category, String message) =>
      _log(levelDebug, category, message);

  /// Returns persisted logs ordered **newest first** (descending key order).
  List<AppLog> getLogs() {
    final box = _box;
    if (box == null || box.isEmpty) {
      return [];
    }

    final keys = box.keys.cast<int>().toList()
      ..sort((a, b) => b.compareTo(a));
    return keys.map((key) => box.get(key)!).toList();
  }

  Future<void> clearLogs() async {
    await _box?.clear();
    _nextKey = 0;
  }

  void _log(String level, String category, String message) {
    final sanitizedMessage = _sanitize(message);
    final entry = AppLog(
      timestamp: _formatTimestamp(DateTime.now()),
      level: level,
      category: category,
      message: sanitizedMessage,
    );

    if (kDebugMode) {
      debugPrint('[$level] $category: $sanitizedMessage');
    }

    _persist(entry);
  }

  Future<void> _persist(AppLog entry) async {
    final box = _box;
    if (box == null) {
      return;
    }

    final key = _nextKey++;
    await box.put(key, entry);
    await _trimOldestIfNeeded(box);
  }

  Future<void> _trimOldestIfNeeded(Box<AppLog> box) async {
    if (box.length <= _maxEntries) {
      return;
    }

    final keys = box.keys.cast<int>().toList()..sort();
    final excess = box.length - _maxEntries;
    await box.deleteAll(keys.take(excess));
  }

  void _restoreNextKey() {
    final box = _box;
    if (box == null || box.isEmpty) {
      _nextKey = 0;
      return;
    }

    _nextKey = box.keys.cast<int>().reduce((a, b) => a > b ? a : b) + 1;
  }

  String _formatTimestamp(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');

    return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)} '
        '${two(dateTime.hour)}:${two(dateTime.minute)}:${two(dateTime.second)}';
  }

  /// Strips or redacts patterns that may contain sensitive data.
  ///
  /// Do not log document numbers, passport/policy numbers, OCR text,
  /// attachment paths, or personal data — callers must avoid them; this
  /// method is a secondary safeguard only.
  String _sanitize(String message) {
    var sanitized = message;

    sanitized = sanitized.replaceAll(
      RegExp(r'[\w.-]+@[\w.-]+\.\w+'),
      '[EMAIL_REDACTED]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\+?\d[\d\s\-()]{7,}\d'),
      '[PHONE_REDACTED]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'(?:/|\\)[^\s]+(?:/|\\)[^\s]*'),
      '[PATH_REDACTED]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(
        r'\b(?:passport|policy|document|doc|license|licence|ssn|sin|nric|'
        r'pan|aadhaar|visa|mrz)\b[^\s]*',
        caseSensitive: false,
      ),
      '[IDENTIFIER_REDACTED]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[A-Z0-9]{2,3}[-\s]?[A-Z0-9]{4,}\b'),
      '[DOC_NUMBER_REDACTED]',
    );

    return sanitized;
  }
}
