import 'package:sambura_core/application/usecase/api_key/list_api_keys_usecase.dart';
import 'package:sambura_core/domain/entities/api_key_entity.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:test/test.dart';

/// Implementação em memória consistente para todos os testes de API Key.
class InMemoryApiKeyRepository implements ApiKeyRepository {
  final List<ApiKeyEntity> _storage = [];
  int _nextId = 1;
  Exception? exceptionToThrow;

  @override
  Future<void> create({
    required int accountId,
    required String name,
    required String keyHash,
    required String prefix,
    DateTime? expiresAt,
  }) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;

    final entity = ApiKeyEntity(
      id: _nextId++,
      accountId: accountId,
      name: name,
      keyHash: keyHash,
      prefix: prefix,
      expiresAt: expiresAt,
      createdAt: DateTime.now().toUtc(),
    );
    _storage.add(entity);
  }

  @override
  Future<List<ApiKeyEntity>> findAllByAccountId(int accountId) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return _storage.where((k) => k.accountId == accountId).toList();
  }

  @override
  Future<ApiKeyEntity?> findByHash(String hash) async => null; // Não usado neste teste

  @override
  Future<ApiKeyEntity> findByAccountId(int accountId) async =>
      _storage.firstWhere((k) => k.accountId == accountId);

  @override
  Future<void> updateLastUsed(int id) async {}

  @override
  Future<void> delete(int id) async => _storage.removeWhere((k) => k.id == id);

  void clear() {
    _storage.clear();
    exceptionToThrow = null;
  }
}

void main() {
  group('ListApiKeysUsecase', () {
    late ListApiKeysUsecase usecase;
    late InMemoryApiKeyRepository repository;

    setUp(() {
      repository = InMemoryApiKeyRepository();
      usecase = ListApiKeysUsecase(repository);
    });

    test('deve retornar lista vazia quando não há API keys', () async {
      // Act
      final result = await usecase.execute(accountId: 123);

      // Assert
      expect(result, isEmpty);
    });

    test('deve retornar lista de API keys do usuário', () async {
      // Arrange
      const accountId = 123;
      // Semeamos o repositório em vez de mockar o retorno
      await repository.create(
        accountId: accountId,
        name: 'key-1',
        keyHash: 'h1',
        prefix: 'sb_',
      );
      await repository.create(
        accountId: accountId,
        name: 'key-2',
        keyHash: 'h2',
        prefix: 'sb_',
      );
      await repository.create(
        accountId: 999,
        name: 'outra-key',
        keyHash: 'h3',
        prefix: 'sb_',
      );

      // Act
      final result = await usecase.execute(accountId: accountId);

      // Assert
      expect(result, hasLength(2));
      expect(result.every((k) => k.accountId == accountId), isTrue);
      expect(result[0].name, equals('key-1'));
      expect(result[1].name, equals('key-2'));
    });

    test('deve propagar exceção quando o repositório falhar', () async {
      // Arrange
      repository.exceptionToThrow = Exception('Database error');

      // Act & Assert
      expect(() => usecase.execute(accountId: 123), throwsA(isA<Exception>()));
    });

    test('deve filtrar corretamente chaves de diferentes usuários', () async {
      // Arrange
      await repository.create(
        accountId: 1,
        name: 'User 1 Key',
        keyHash: 'h1',
        prefix: 'sb_',
      );
      await repository.create(
        accountId: 2,
        name: 'User 2 Key',
        keyHash: 'h2',
        prefix: 'sb_',
      );

      // Act
      final result = await usecase.execute(accountId: 1);

      // Assert
      expect(result, hasLength(1));
      expect(result.first.name, equals('User 1 Key'));
    });
  });
}
