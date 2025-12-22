import 'dart:io';

class AppConfig {
  static final String baseUrl =
      Platform.environment['APP_BASE_URL'] ?? 'http://localhost:8080';
}
