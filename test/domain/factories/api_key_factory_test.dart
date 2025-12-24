import 'package:sambura_core/domain/entities/api_key_entity.dart';
import 'package:sambura_core/domain/factories/api_key_factory.dart';
import 'package:test/test.dart';

void main() {
  group('ApiKeyFactory', () {
    group('create', () {
      test('deve criar nova API key com campos obrigatórios', () {
        // Arrange
        const accountId = 123;
        const name = 'test-key';
        const keyHash = 'hash123';
        const prefix = 'sb_live_';

        // Act
        final apiKey = ApiKeyFactory.create(
          accountId: accountId,
          name: name,
          keyHash: keyHash,
          prefix: prefix,
        );

        // Assert
        expect(apiKey, isA<ApiKeyEntity>());
        expect(apiKey.accountId, equals(accountId));
        expect(apiKey.name, equals(name));
        expect(apiKey.keyHash, equals(keyHash));
        expect(apiKey.prefix, equals(prefix));
        expect(apiKey.createdAt, isNotNull);
        expect(apiKey.id, isNull);
        expect(apiKey.lastUsedAt, isNull);
        expect(apiKey.expiresAt, isNull);
      });

      test('deve criar API key com data de expiração', () {
        // Arrange
        final expiresAt = DateTime.now().add(Duration(days: 30));

        // Act
        final apiKey = ApiKeyFactory.create(
          accountId: 1,
          name: 'test-key',
          keyHash: 'hash',
          prefix: 'sb_live_',
          expiresAt: expiresAt,
        );

        // Assert
        expect(apiKey.expiresAt, equals(expiresAt));
      });

      test('deve criar com createdAt em UTC', () {
        // Act
        final apiKey = ApiKeyFactory.create(
          accountId: 1,
          name: 'test-key',
          keyHash: 'hash',
          prefix: 'sb_live_',
        );

        // Assert
        expect(apiKey.createdAt!.isUtc, isTrue);
      });
    });

    group('restore', () {
      test('deve restaurar API key completa do banco de dados', () {
        // Arrange
        const id = 1;
        const accountId = 123;
        const name = 'restored-key';
        const keyHash = 'hash123';
        const prefix = 'sb_live_';
        final createdAt = DateTime.parse('2024-01-01T10:00:00Z');
        final lastUsedAt = DateTime.parse('2024-01-15T10:00:00Z');
        final expiresAt = DateTime.parse('2024-12-31T23:59:59Z');

        // Act
        final apiKey = ApiKeyFactory.restore(
          id: id,
          accountId: accountId,
          name: name,
          keyHash: keyHash,
          prefix: prefix,
          createdAt: createdAt,
          lastUsedAt: lastUsedAt,
          expiresAt: expiresAt,
        );

        // Assert
        expect(apiKey.id, equals(id));
        expect(apiKey.accountId, equals(accountId));
        expect(apiKey.name, equals(name));
        expect(apiKey.keyHash, equals(keyHash));
        expect(apiKey.prefix, equals(prefix));
        expect(apiKey.createdAt, equals(createdAt));
        expect(apiKey.lastUsedAt, equals(lastUsedAt));
        expect(apiKey.expiresAt, equals(expiresAt));
      });

      test('deve restaurar API key sem campos opcionais', () {
        // Act
        final apiKey = ApiKeyFactory.restore(
          id: 1,
          accountId: 123,
          name: 'key',
          keyHash: 'hash',
          prefix: 'sb_live_',
          createdAt: DateTime.now(),
        );

        // Assert
        expect(apiKey.id, equals(1));
        expect(apiKey.lastUsedAt, isNull);
        expect(apiKey.expiresAt, isNull);
      });
    });

    group('diferença entre create e restore', () {
      test(
        'create deve gerar novo createdAt, restore deve usar o fornecido',
        () {
          // Arrange
          final pastDate = DateTime.parse('2020-01-01T00:00:00Z');

          // Act
          final created = ApiKeyFactory.create(
            accountId: 1,
            name: 'new-key',
            keyHash: 'hash',
            prefix: 'sb_live_',
          );

          final restored = ApiKeyFactory.restore(
            id: 1,
            accountId: 1,
            name: 'old-key',
            keyHash: 'hash',
            prefix: 'sb_live_',
            createdAt: pastDate,
          );

          // Assert
          expect(created.createdAt!.isAfter(pastDate), isTrue);
          expect(restored.createdAt, equals(pastDate));
        },
      );

      test('create não deve ter ID, restore deve ter', () {
        // Act
        final created = ApiKeyFactory.create(
          accountId: 1,
          name: 'key',
          keyHash: 'hash',
          prefix: 'sb_live_',
        );

        final restored = ApiKeyFactory.restore(
          id: 42,
          accountId: 1,
          name: 'key',
          keyHash: 'hash',
          prefix: 'sb_live_',
          createdAt: DateTime.now(),
        );

        // Assert
        expect(created.id, isNull);
        expect(restored.id, equals(42));
      });
    });
  });
}
