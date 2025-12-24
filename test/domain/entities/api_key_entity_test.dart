import 'package:sambura_core/domain/entities/api_key_entity.dart';
import 'package:test/test.dart';

void main() {
  group('ApiKeyEntity', () {
    test('deve criar ApiKeyEntity com todos os campos', () {
      // Arrange
      const id = 1;
      const accountId = 42;
      const name = 'Production Key';
      const keyHash = 'hashed_key_value';
      const prefix = 'sk_prod';
      final createdAt = DateTime.parse('2024-01-01T10:00:00Z');
      final lastUsedAt = DateTime.parse('2024-01-15T10:00:00Z');
      final expiresAt = DateTime.parse('2025-01-01T10:00:00Z');

      // Act
      final apiKey = ApiKeyEntity(
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

    test('deve criar ApiKeyEntity sem campos opcionais', () {
      // Act
      final apiKey = ApiKeyEntity(
        accountId: 42,
        name: 'Test Key',
        keyHash: 'hashed_value',
        prefix: 'sk_test',
      );

      // Assert
      expect(apiKey.id, isNull);
      expect(apiKey.createdAt, isNull);
      expect(apiKey.lastUsedAt, isNull);
      expect(apiKey.expiresAt, isNull);
    });

    group('copyWith', () {
      test('deve criar cópia com id atualizado', () {
        // Arrange
        final original = ApiKeyEntity(
          accountId: 42,
          name: 'Original',
          keyHash: 'hash',
          prefix: 'sk_',
        );

        // Act
        final copied = original.copyWith(id: 1);

        // Assert
        expect(copied.id, equals(1));
        expect(copied.accountId, equals(original.accountId));
        expect(copied.name, equals(original.name));
      });

      test('deve criar cópia com accountId atualizado', () {
        // Arrange
        final original = ApiKeyEntity(
          id: 1,
          accountId: 42,
          name: 'Original',
          keyHash: 'hash',
          prefix: 'sk_',
        );

        // Act
        final copied = original.copyWith(accountId: 99);

        // Assert
        expect(copied.accountId, equals(99));
        expect(copied.id, equals(original.id));
      });

      test('deve criar cópia com name atualizado', () {
        // Arrange
        final original = ApiKeyEntity(
          accountId: 42,
          name: 'Original',
          keyHash: 'hash',
          prefix: 'sk_',
        );

        // Act
        final copied = original.copyWith(name: 'Updated');

        // Assert
        expect(copied.name, equals('Updated'));
        expect(copied.accountId, equals(original.accountId));
      });

      test('deve criar cópia com keyHash atualizado', () {
        // Arrange
        final original = ApiKeyEntity(
          accountId: 42,
          name: 'Original',
          keyHash: 'hash',
          prefix: 'sk_',
        );

        // Act
        final copied = original.copyWith(keyHash: 'new_hash');

        // Assert
        expect(copied.keyHash, equals('new_hash'));
      });

      test('deve criar cópia com prefix atualizado', () {
        // Arrange
        final original = ApiKeyEntity(
          accountId: 42,
          name: 'Original',
          keyHash: 'hash',
          prefix: 'sk_',
        );

        // Act
        final copied = original.copyWith(prefix: 'pk_');

        // Assert
        expect(copied.prefix, equals('pk_'));
      });

      test('deve criar cópia com expiresAt atualizado', () {
        // Arrange
        final original = ApiKeyEntity(
          accountId: 42,
          name: 'Original',
          keyHash: 'hash',
          prefix: 'sk_',
        );
        final newExpiresAt = DateTime.parse('2025-12-31T23:59:59Z');

        // Act
        final copied = original.copyWith(expiresAt: newExpiresAt);

        // Assert
        expect(copied.expiresAt, equals(newExpiresAt));
      });

      test('deve criar cópia com lastUsedAt atualizado', () {
        // Arrange
        final original = ApiKeyEntity(
          accountId: 42,
          name: 'Original',
          keyHash: 'hash',
          prefix: 'sk_',
        );
        final newLastUsedAt = DateTime.parse('2024-06-15T12:00:00Z');

        // Act
        final copied = original.copyWith(lastUsedAt: newLastUsedAt);

        // Assert
        expect(copied.lastUsedAt, equals(newLastUsedAt));
      });

      test('deve criar cópia com createdAt atualizado', () {
        // Arrange
        final original = ApiKeyEntity(
          accountId: 42,
          name: 'Original',
          keyHash: 'hash',
          prefix: 'sk_',
        );
        final newCreatedAt = DateTime.parse('2024-01-01T00:00:00Z');

        // Act
        final copied = original.copyWith(createdAt: newCreatedAt);

        // Assert
        expect(copied.createdAt, equals(newCreatedAt));
      });

      test('deve criar cópia com múltiplos campos atualizados', () {
        // Arrange
        final original = ApiKeyEntity(
          id: 1,
          accountId: 42,
          name: 'Original',
          keyHash: 'hash',
          prefix: 'sk_',
        );
        final newLastUsedAt = DateTime.parse('2024-06-15T12:00:00Z');

        // Act
        final copied = original.copyWith(
          name: 'Updated Name',
          keyHash: 'new_hash',
          lastUsedAt: newLastUsedAt,
        );

        // Assert
        expect(copied.name, equals('Updated Name'));
        expect(copied.keyHash, equals('new_hash'));
        expect(copied.lastUsedAt, equals(newLastUsedAt));
        expect(copied.id, equals(original.id));
        expect(copied.accountId, equals(original.accountId));
      });

      test('deve manter valores originais quando não especificados', () {
        // Arrange
        final createdAt = DateTime.parse('2024-01-01T10:00:00Z');
        final original = ApiKeyEntity(
          id: 1,
          accountId: 42,
          name: 'Original',
          keyHash: 'hash',
          prefix: 'sk_',
          createdAt: createdAt,
        );

        // Act
        final copied = original.copyWith(name: 'Updated');

        // Assert
        expect(copied.id, equals(original.id));
        expect(copied.accountId, equals(original.accountId));
        expect(copied.keyHash, equals(original.keyHash));
        expect(copied.prefix, equals(original.prefix));
        expect(copied.createdAt, equals(original.createdAt));
      });

      test('deve manter imutabilidade - original não deve mudar', () {
        // Arrange
        const originalName = 'Original';
        final original = ApiKeyEntity(
          accountId: 42,
          name: originalName,
          keyHash: 'hash',
          prefix: 'sk_',
        );

        // Act
        original.copyWith(name: 'Updated');

        // Assert
        expect(original.name, equals(originalName));
      });
    });
  });
}
