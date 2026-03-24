import 'dart:io';
import 'package:logging/logging.dart';

class LoggerConfig {
  static bool _initialized = false;

  static void initialize({
    Level level = Level.INFO,
    String filePath = '/app/logs',
  }) {
    if (_initialized) return;

    Directory logDir = Directory(filePath);
    try {
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }
    } catch (e) {
      // Fallback to a writable temp directory if the default is not available.
      final tempPath = '${Directory.systemTemp.path}/sambura_core_logs';
      logDir = Directory(tempPath);
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }
    }

    final logFile = File('${logDir.path}/app.log');

    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      final timestamp = record.time.toIso8601String();
      final String message = record.message;

      logFile.writeAsStringSync(
        "$message\n",
        mode: FileMode.append,
        flush: true,
      );

      final formattedLine =
          '[$timestamp] [${record.loggerName}] ${record.level.name}: $message';

      if (record.level >= Level.SEVERE) {
        stderr.writeln(formattedLine);
        if (record.error != null) stderr.writeln('ERROR: ${record.error}');
        if (record.stackTrace != null) {
          stderr.writeln('STACKTRACE: ${record.stackTrace}');
        }
      } else {
        stdout.writeln(formattedLine);
      }
    });

    _initialized = true;
  }

  static Logger getLogger(String name) => Logger(name);
}
