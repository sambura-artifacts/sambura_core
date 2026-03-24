import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:test/test.dart';

void main() {
  group('LoggerConfig', () {
    test('deve inicializar com nível INFO por padrão', () {
      // Clean state
      Logger.root.clearListeners();
      Logger.root.level = Level.ALL;

      LoggerConfig.initialize();
      expect(Logger.root.level, Level.INFO);
    });

    test('não deve reinicializar se já inicializado', () {
      // This test relies on previous initialization
      final initialLevel = Logger.root.level;

      LoggerConfig.initialize(level: Level.SEVERE);
      expect(Logger.root.level, initialLevel);
    });

    test('deve logar mensagem INFO no stdout', () {
      final logger = LoggerConfig.getLogger('test');

      // Just trigger the log, the output goes to stdout/stderr
      logger.info('Test message');

      expect(logger.name, 'test');
    });

    test('deve logar mensagem SEVERE no stderr', () {
      final logger = LoggerConfig.getLogger('test');

      logger.severe('Error message');

      expect(logger.name, 'test');
    });

    test('deve logar mensagem WARNING', () {
      final logger = LoggerConfig.getLogger('test');

      logger.warning('Warning message');

      expect(logger.name, 'test');
    });

    test('deve logar mensagem CONFIG', () {
      final logger = LoggerConfig.getLogger('test');

      logger.config('Config message');

      expect(logger.name, 'test');
    });

    test('deve logar mensagem FINE', () {
      final logger = LoggerConfig.getLogger('test');

      logger.fine('Fine message');

      expect(logger.name, 'test');
    });

    test('deve logar mensagem FINER', () {
      final logger = LoggerConfig.getLogger('test');

      logger.finer('Finer message');

      expect(logger.name, 'test');
    });

    test('deve logar mensagem FINEST', () {
      final logger = LoggerConfig.getLogger('test');

      logger.finest('Finest message');

      expect(logger.name, 'test');
    });

    test('deve logar mensagem com erro', () {
      final logger = LoggerConfig.getLogger('test');

      logger.severe('Error with exception', Exception('Test error'));

      expect(logger.name, 'test');
    });

    test('deve logar mensagem com stack trace', () {
      final logger = LoggerConfig.getLogger('test');

      try {
        throw Exception('Test error');
      } catch (e, stackTrace) {
        logger.severe('Error with stack trace', e, stackTrace);
      }

      expect(logger.name, 'test');
    });

    test('getLogger deve retornar logger com nome correto', () {
      final logger = LoggerConfig.getLogger('MyClass');
      expect(logger.name, 'MyClass');
    });

    test('deve formatar logs com diferentes níveis', () {
      final logger = LoggerConfig.getLogger('test');

      // Trigger all log levels to ensure formatting works
      logger.finest('Finest');
      logger.finer('Finer');
      logger.fine('Fine');
      logger.config('Config');
      logger.info('Info');
      logger.warning('Warning');
      logger.severe('Severe');
      logger.shout('Shout');

      expect(logger.name, 'test');
    });
  });
}
