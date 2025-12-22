import 'dart:io';
import 'package:logging/logging.dart';

/// Configuração centralizada de logging para o Samburá
class LoggerConfig {
  static bool _initialized = false;

  /// Inicializa o sistema de logging
  static void initialize({Level level = Level.INFO}) {
    if (_initialized) return;

    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      final emoji = _getEmojiForLevel(record.level);
      final timestamp = record.time.toIso8601String();
      final loggerName = record.loggerName;
      final level = record.level.name;
      final message = record.message;

      // Formata a mensagem com cores para terminal
      final formattedMessage = _formatMessage(
        emoji: emoji,
        timestamp: timestamp,
        loggerName: loggerName,
        level: level,
        message: message,
      );

      // Imprime no stderr para níveis de erro, warning no stdout para os demais
      if (record.level >= Level.SEVERE) {
        stderr.writeln(formattedMessage);
      } else {
        stdout.writeln(formattedMessage);
      }

      // Se houver erro ou stack trace, imprime também
      if (record.error != null) {
        stderr.writeln('  ❌ Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        stderr.writeln('  📚 Stack trace:\n${record.stackTrace}');
      }
    });

    _initialized = true;
  }

  /// Obtém emoji apropriado para o nível de log
  static String _getEmojiForLevel(Level level) {
    if (level == Level.SEVERE) return '🔥';
    if (level == Level.WARNING) return '⚠️';
    if (level == Level.INFO) return 'ℹ️';
    if (level == Level.CONFIG) return '⚙️';
    if (level == Level.FINE) return '🔍';
    if (level == Level.FINER) return '🔬';
    if (level == Level.FINEST) return '🧬';
    return '📝';
  }

  /// Formata a mensagem de log
  static String _formatMessage({
    required String emoji,
    required String timestamp,
    required String loggerName,
    required String level,
    required String message,
  }) {
    return '$emoji [$timestamp] [$loggerName] $level: $message';
  }

  /// Cria um logger para uma classe específica
  static Logger getLogger(String name) {
    return Logger(name);
  }
}
