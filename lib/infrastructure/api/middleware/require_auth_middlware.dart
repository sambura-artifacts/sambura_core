import 'package:shelf/shelf.dart';
import 'dart:convert';

class RequireAuthMiddleware {
  static Middleware check() {
    return (Handler innerHandler) {
      return (Request request) {
        final user = request.context['user'];

        if (user == null) {
          return Response(
            401,
            body: jsonEncode({
              'error': 'Acesso negado. Token ausente ou inválido.',
            }),
            headers: {'content-type': 'application/json'},
          );
        }

        return innerHandler(request);
      };
    };
  }
}
