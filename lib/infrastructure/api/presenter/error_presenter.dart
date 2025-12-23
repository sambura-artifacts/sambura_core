import 'dart:convert';
import 'package:shelf/shelf.dart';

class ErrorPresenter {
  static Response badRequest(String detail, String instance, String baseUrl) {
    final body = {
      'type': '$baseUrl/docs/errors/bad-request',
      'title': 'Bad Request',
      'status': 400,
      'detail': detail,
      'instance': instance,
    };

    return Response.badRequest(
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/problem+json'},
    );
  }

  static Response notFound(String detail, String instance, String baseUrl) {
    final body = jsonEncode({
      "type": "about:blank",
      "title": "Not Found",
      "status": 404,
      "detail": detail,
      "instance": instance,
      "_links": {
        "self": {"href": "$baseUrl/$instance", "method": "GET"},
        "home": {"href": "$baseUrl/", "method": "GET"},
      },
    });

    return Response.notFound(
      body,
      headers: {'Content-Type': 'application/problem+json'},
    );
  }

  static Response internalServerError(
    String detail,
    String instance,
    String baseUrl, {
    Object? error,
    StackTrace? stack,
  }) {
    print('🚨 [SERVER ERROR] em $instance: $error');
    if (stack != null) print(stack);

    final body = jsonEncode({
      "type": "$baseUrl/docs/errors/internal-server-error",
      "title": "Internal Server Error",
      "status": 500,
      "detail": detail,
      "instance": instance,
      "_links": {
        "self": {"href": "$baseUrl$instance", "method": "POST"},
        "home": {"href": "$baseUrl/", "method": "GET"},
      },
    });

    return Response.internalServerError(
      body: body,
      headers: {'Content-Type': 'application/problem+json'},
    );
  }
}
