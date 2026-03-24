import 'dart:io';

class AppConfig {
  static final String baseUrl =
      Platform.environment['SAMBURA_BASE_URL'] ?? 'http://localhost:8080';

  static const String npmApiPrefix = '/api/v1/npm';

  static final String environment =
      Platform.environment['APP_ENV'] ?? 'development';
}
