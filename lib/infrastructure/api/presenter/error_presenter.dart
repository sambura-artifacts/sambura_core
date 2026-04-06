import 'dart:convert';
import 'package:shelf/shelf.dart';

import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class ErrorPresenter {
  static Response fromException(Object e, String instance, String baseUrl) {
    if (e is ExternalServiceUnavailableException) {
      return serviceUnavailable(e.message, instance, baseUrl);
    }

    if (e is ExternalResourceNotFoundException) {
      return notFound(e.message, instance, baseUrl);
    }

    if (e is DomainException) {
      if (e is RepositoryNotFoundException || e is ArtifactNotFoundException) {
        return notFound(e.message, instance, baseUrl);
      }
      if (e is VersionConflictException) {
        return conflict(e.message, instance, baseUrl);
      }
      return badRequest(e.message, instance, baseUrl);
    }

    if (e is InfrastructureException) {
      return internalServerError(e.message, instance, baseUrl, error: e);
    }

    if (e is SecurityException) {
      return forbidden(e.message, instance, baseUrl);
    }

    return internalServerError(
      'Erro interno inesperado.',
      instance,
      baseUrl,
      error: e,
    );
  }

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
    });
    return Response.notFound(
      body,
      headers: {'Content-Type': 'application/problem+json'},
    );
  }

  static Response notFoundRoute(String instance, String baseUrl) {
    return notFound('Route not found', instance, baseUrl);
  }

  static Response conflict(String detail, String instance, String baseUrl) {
    final body = jsonEncode({
      "type": "$baseUrl/docs/errors/conflict",
      "title": "Conflict",
      "status": 409,
      "detail": detail,
      "instance": instance,
    });
    return Response(
      409,
      body: body,
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
    final body = jsonEncode({
      "type": "$baseUrl/docs/errors/internal-server-error",
      "title": "Internal Server Error",
      "status": 500,
      "detail": detail,
      "instance": instance,
    });
    return Response.internalServerError(
      body: body,
      headers: {'Content-Type': 'application/problem+json'},
    );
  }

  static Response serviceUnavailable(
    String detail,
    String instance,
    String baseUrl,
  ) {
    final body = jsonEncode({
      "type": "$baseUrl/docs/errors/service-unavailable",
      "title": "Service Unavailable",
      "status": 503,
      "detail": detail,
      "instance": instance,
    });
    return Response(
      503,
      body: body,
      headers: {'Content-Type': 'application/problem+json'},
    );
  }

  static Response forbidden(String detail, String instance, String baseUrl) {
    final body = jsonEncode({
      "type": "$baseUrl/docs/errors/forbidden",
      "title": "Forbidden",
      "status": 403,
      "detail": detail,
      "instance": instance,
    });
    return Response(
      403,
      body: body,
      headers: {'Content-Type': 'application/problem+json'},
    );
  }
}
