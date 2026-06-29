import 'package:hive/hive.dart';

part 'app_log.g.dart';

/// A single application log entry persisted locally in Hive.
///
/// Contains metadata only — never store PII, document numbers, OCR text,
/// attachment paths, or other sensitive data in [message].
@HiveType(typeId: 0)
class AppLog {
  const AppLog({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
  });

  @HiveField(0)
  final String timestamp;

  @HiveField(1)
  final String level;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String message;
}
