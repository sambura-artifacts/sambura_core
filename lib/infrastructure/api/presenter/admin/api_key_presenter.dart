import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sambura_core/domain/entities/api_key_entity.dart';
import 'package:sambura_core/application/usecase/api_key/generate_api_key_usecase.dart';

class ApiKeyPresenter {
  /// Resposta de sucesso ao criar uma nova API key
  static Response created(GenerateApiKeyResult result) {
    final body = {
      'message':
          'Chave forjada com sucesso! Guarda bem, ela não aparece de novo.',
      'data': {
        'name': result.name,
        'api_key': result.plainKey,
        'prefix': result.prefix,
      },
      '_links': {
        'self': {'href': '/api/v1/admin/api-keys', 'method': 'POST'},
        'list': {'href': '/api/v1/admin/api-keys', 'method': 'GET'},
      },
    };

    return Response.ok(
      jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Resposta de sucesso ao listar API keys
  static Response list(List<ApiKeyEntity> keys) {
    final body = {
      'data': keys
          .map(
            (k) => {
              'id': k.id,
              'name': k.name,
              'prefix': k.prefix,
              'last_used_at': k.lastUsedAt?.toIso8601String(),
              'created_at': k.createdAt?.toIso8601String(),
              'expires_at': k.expiresAt?.toIso8601String(),
            },
          )
          .toList(),
      'meta': {'total': keys.length},
      '_links': {
        'self': {'href': '/api/v1/admin/api-keys', 'method': 'GET'},
        'create': {'href': '/api/v1/admin/api-keys', 'method': 'POST'},
      },
    };

    return Response.ok(
      jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Resposta de sucesso ao revogar uma API key
  static Response revoked(int keyId) {
    final body = {
      'message': 'Chave incinerada com sucesso!',
      'data': {'id': keyId, 'revoked_at': DateTime.now().toIso8601String()},
      '_links': {
        'list': {'href': '/api/v1/admin/api-keys', 'method': 'GET'},
      },
    };

    return Response.ok(
      jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Resposta de erro quando o nome da chave não é fornecido
  static Response missingKeyName(String instance) {
    final body = {
      'type': 'about:blank',
      'title': 'Bad Request',
      'status': 400,
      'detail': 'Dê um nome pra essa chave, cria!',
      'instance': instance,
      '_links': {
        'self': {'href': instance, 'method': 'POST'},
        'docs': {'href': '/docs/api-keys', 'method': 'GET'},
      },
    };

    return Response.badRequest(
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/problem+json'},
    );
  }

  /// Resposta de erro quando o ID fornecido é inválido
  static Response invalidKeyId(String id, String instance) {
    final body = {
      'type': 'about:blank',
      'title': 'Bad Request',
      'status': 400,
      'detail': 'ID da chave inválido: $id',
      'instance': instance,
      '_links': {
        'self': {'href': instance, 'method': 'DELETE'},
        'list': {'href': '/api/v1/admin/api-keys', 'method': 'GET'},
      },
    };

    return Response.badRequest(
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/problem+json'},
    );
  }

  /// Resposta de erro quando o usuário não está autenticado
  static Response unauthorized(String instance) {
    final body = {
      'type': 'about:blank',
      'title': 'Unauthorized',
      'status': 401,
      'detail': 'Autenticação necessária para acessar este recurso',
      'instance': instance,
      '_links': {
        'login': {'href': '/api/v1/auth/login', 'method': 'POST'},
      },
    };

    return Response.unauthorized(
      jsonEncode(body),
      headers: {'Content-Type': 'application/problem+json'},
    );
  }

  /// Resposta de erro interno do servidor
  static Response internalServerError(
    String detail,
    String instance, {
    Object? error,
    StackTrace? stack,
  }) {
    print('🚨 [API KEY ERROR] em $instance: $error');
    if (stack != null) print(stack);

    final body = {
      'type': 'about:blank',
      'title': 'Internal Server Error',
      'status': 500,
      'detail': detail,
      'instance': instance,
      '_links': {
        'self': {'href': instance},
        'home': {'href': '/api/v1', 'method': 'GET'},
      },
    };

    return Response.internalServerError(
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/problem+json'},
    );
  }
}
