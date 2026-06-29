import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/app_log.dart';
import '../../services/app_info_service.dart';
import '../../theme/app_brand.dart';
import 'logging_service.dart';

/// Builds and writes sanitized debug log exports to the temp directory.
class LogExportService {
  LogExportService._();

  static final LogExportService instance = LogExportService._();

  static const _headerRule = '==================================================';
  static const _entryRule = '--------------------------------------------------';

  /// Generates export text from persisted logs and writes a temp TXT file.
  ///
  /// Returns the written [File] and the same textual [content].
  Future<({File file, String content})> generateExportFile({
    List<AppLog>? logs,
  }) async {
    final entries = logs ?? LoggingService.instance.getLogs();
    final content = buildExportContent(entries);
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, _exportFilename()));
    await file.writeAsString(content, flush: true);
    return (file: file, content: content);
  }

  String buildExportContent(List<AppLog> logs) {
    final appInfo = AppInfoService.instance;
    final generatedAt = _formatTimestamp(DateTime.now());

    final buffer = StringBuffer()
      ..writeln(_headerRule)
      ..writeln('${AppBrand.name} Debug Logs')
      ..writeln('Generated: $generatedAt')
      ..writeln('Version: ${appInfo.versionSync ?? 'Unknown'}')
      ..writeln('Build Number: ${appInfo.buildNumberSync ?? 'Unknown'}');

    final releaseChannel = appInfo.releaseChannel;
    if (releaseChannel.isNotEmpty) {
      buffer.writeln('Release Channel: $releaseChannel');
    }

    buffer
      ..writeln(_headerRule)
      ..writeln();

    for (final log in logs) {
      buffer
        ..writeln('[${log.timestamp}]')
        ..writeln('[${log.level}]')
        ..writeln('[${log.category}]')
        ..writeln(log.message)
        ..writeln()
        ..writeln(_entryRule)
        ..writeln();
    }

    return buffer.toString().trimRight();
  }

  String _exportFilename() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');

    return 'renewvault_logs_${now.year}_${two(now.month)}_${two(now.day)}_'
        '${two(now.hour)}_${two(now.minute)}.txt';
  }

  String _formatTimestamp(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');

    return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)} '
        '${two(dateTime.hour)}:${two(dateTime.minute)}:${two(dateTime.second)}';
  }
}
