import 'dart:io';
import 'package:test/test.dart';
import '../../lib/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('deve retornar baseUrl do ambiente ou padrão', () {
      expect(AppConfig.baseUrl, isNotEmpty);
      expect(
        AppConfig.baseUrl,
        anyOf(contains('http://localhost:8080'), contains('http')),
      );
    });

    test('deve retornar baseUrl do ambiente quando definido', () {
      // Save current env
      final originalValue = Platform.environment['SAMBURA_BASE_URL'];

      // Can't actually set env vars in tests, but we can verify the current value
      expect(AppConfig.baseUrl, isNotEmpty);

      // If env var is set, it should use it, otherwise default
      if (originalValue != null) {
        expect(AppConfig.baseUrl, equals(originalValue));
      } else {
        expect(AppConfig.baseUrl, equals('http://localhost:8080'));
      }
    });

    test('npmApiPrefix deve ser constante', () {
      expect(AppConfig.npmApiPrefix, '/api/v1/npm');
    });

    test('deve retornar environment do ambiente ou padrão', () {
      expect(AppConfig.environment, isNotEmpty);
      expect(
        AppConfig.environment,
        anyOf(
          equals('development'),
          equals('production'),
          equals('test'),
          isNotEmpty,
        ),
      );
    });

    test('environment deve retornar valor do ambiente quando definido', () {
      final originalValue = Platform.environment['APP_ENV'];

      expect(AppConfig.environment, isNotEmpty);

      // If env var is set, it should use it, otherwise default
      if (originalValue != null) {
        expect(AppConfig.environment, equals(originalValue));
      } else {
        expect(AppConfig.environment, equals('development'));
      }
    });
  });
}
