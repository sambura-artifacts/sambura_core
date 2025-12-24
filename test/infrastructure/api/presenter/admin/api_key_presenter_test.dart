import 'dart:convert';
import 'package:sambura_core/application/usecase/api_key/generate_api_key_usecase.dart';
import 'package:sambura_core/domain/entities/api_key_entity.dart';
import 'package:sambura_core/infrastructure/api/presenter/admin/api_key_presenter.dart';
import 'package:test/test.dart';

void main() {
  group('ApiKeyPresenter', () {
    group('created', () {
      test('deve retornar response 200 com chave criada', () async {
        // Arrange
        final result = GenerateApiKeyResult(
          'test-key',
          'sb_live_abc123',
          'sb_live_',
        );

        // Act
        final response = ApiKeyPresenter.created(result);

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.headers['Content-Type'], contains('application/json'));

        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['message'], isNotNull);
        expect(body['data']['name'], equals('test-key'));
        expect(body['data']['api_key'], equals('sb_live_abc123'));
        expect(body['data']['prefix'], equals('sb_live_'));
        expect(body['_links'], isNotNull);
      });

      test('deve incluir links HATEOAS', () async {
        // Arrange
        final result = GenerateApiKeyResult(
          'test-key',
          'sb_live_abc123',
          'sb_live_',
        );

        // Act
        final response = ApiKeyPresenter.created(result);
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;

        // Assert
        expect(body['_links']['self'], isNotNull);
        expect(body['_links']['list'], isNotNull);
      });
    });

    group('list', () {
      test('deve retornar response 200 com lista vazia', () async {
        // Act
        final response = ApiKeyPresenter.list([]);

        // Assert
        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'], isEmpty);
        expect(body['meta']['total'], equals(0));
      });

      test('deve retornar response 200 com lista de chaves', () async {
        // Arrange
        final keys = [
          ApiKeyEntity(
            id: 1,
            accountId: 123,
            name: 'key-1',
            keyHash: 'hash1',
            prefix: 'sb_live_',
            createdAt: DateTime.parse('2024-01-01T10:00:00Z'),
            lastUsedAt: null,
          ),
          ApiKeyEntity(
            id: 2,
            accountId: 123,
            name: 'key-2',
            keyHash: 'hash2',
            prefix: 'sb_live_',
            createdAt: DateTime.parse('2024-01-02T10:00:00Z'),
            lastUsedAt: DateTime.parse('2024-01-03T10:00:00Z'),
          ),
        ];

        // Act
        final response = ApiKeyPresenter.list(keys);

        // Assert
        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'], hasLength(2));
        expect(body['meta']['total'], equals(2));
        expect(body['data'][0]['id'], equals(1));
        expect(body['data'][0]['name'], equals('key-1'));
        expect(body['data'][1]['last_used_at'], isNotNull);
      });

      test('deve incluir links HATEOAS', () async {
        // Act
        final response = ApiKeyPresenter.list([]);
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;

        // Assert
        expect(body['_links']['self'], isNotNull);
        expect(body['_links']['create'], isNotNull);
      });
    });

    group('revoked', () {
      test('deve retornar response 200 quando chave é revogada', () async {
        // Arrange
        const keyId = 123;

        // Act
        final response = ApiKeyPresenter.revoked(keyId);

        // Assert
        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['message'], isNotNull);
        expect(body['data']['id'], equals(keyId));
        expect(body['data']['revoked_at'], isNotNull);
        expect(body['_links']['list'], isNotNull);
      });
    });

    group('missingKeyName', () {
      test('deve retornar response 400 com detalhes do erro', () async {
        // Arrange
        const instance = '/api/v1/admin/api-keys';

        // Act
        final response = ApiKeyPresenter.missingKeyName(instance);

        // Assert
        expect(response.statusCode, equals(400));
        expect(
          response.headers['Content-Type'],
          equals('application/problem+json'),
        );

        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['type'], equals('about:blank'));
        expect(body['title'], equals('Bad Request'));
        expect(body['status'], equals(400));
        expect(body['detail'], isNotNull);
        expect(body['instance'], equals(instance));
      });
    });

    group('invalidKeyId', () {
      test('deve retornar response 400 com ID inválido', () async {
        // Arrange
        const invalidId = 'abc';
        const instance = '/api/v1/admin/api-keys/abc';

        // Act
        final response = ApiKeyPresenter.invalidKeyId(invalidId, instance);

        // Assert
        expect(response.statusCode, equals(400));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['status'], equals(400));
        expect(body['detail'], contains(invalidId));
      });
    });

    group('unauthorized', () {
      test('deve retornar response 401', () async {
        // Arrange
        const instance = '/api/v1/admin/api-keys/123';

        // Act
        final response = ApiKeyPresenter.unauthorized(instance);

        // Assert
        expect(response.statusCode, equals(401));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['status'], equals(401));
        expect(body['title'], equals('Unauthorized'));
      });
    });

    group('internalServerError', () {
      test('deve retornar response 500', () async {
        // Arrange
        const detail = 'Erro interno';
        const instance = '/api/v1/admin/api-keys';

        // Act
        final response = ApiKeyPresenter.internalServerError(detail, instance);

        // Assert
        expect(response.statusCode, equals(500));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['status'], equals(500));
        expect(body['title'], equals('Internal Server Error'));
        expect(body['detail'], equals(detail));
      });
    });
  });
}
