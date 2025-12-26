import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';

Middleware structuredLogMiddleware() {
  final log = Logger('HTTP');

  return (Handler innerHandler) {
    return (Request request) async {
      final watch = Stopwatch()..start();
      final response = await innerHandler(request);
      watch.stop();

      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'method': request.method,
        'path': request.url.path,
        'status': response.statusCode,
        'latency_ms': watch.elapsedMilliseconds,
        'user_agent': request.headers['user-agent'] ?? 'unknown',
      };

      final message = jsonEncode(logEntry);

      if (response.statusCode >= 500) {
        log.severe(message);
      } else if (response.statusCode >= 400) {
        log.warning(message);
      } else {
        log.info(message);
      }

      return response;
    };
  };
}
