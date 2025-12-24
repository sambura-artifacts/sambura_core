import 'package:sambura_core/application/usecase/api_key/generate_api_key_usecase.dart';
import 'package:sambura_core/domain/entities/api_key_entity.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:test/test.dart';

/// Implementação em memória para testes unitários.
/// Inclui suporte para simulação de exceções.
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
  Future<ApiKeyEntity?> findByHash(String hash) async {
    try {
      return _storage.firstWhere((k) => k.keyHash == hash);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ApiKeyEntity>> findAllByAccountId(int accountId) async {
    return _storage.where((k) => k.accountId == accountId).toList();
  }

  @override
  Future<ApiKeyEntity> findByAccountId(int accountId) async {
    return _storage.firstWhere((k) => k.accountId == accountId);
  }

  @override
  Future<void> updateLastUsed(int id) async {
    final index = _storage.indexWhere((k) => k.id == id);
    if (index != -1) {
      final key = _storage[index];
      _storage[index] = key.copyWith(lastUsedAt: DateTime.now().toUtc());
    }
  }

  @override
  Future<void> delete(int id) async {
    _storage.removeWhere((k) => k.id == id);
  }

  void clear() {
    _storage.clear();
    exceptionToThrow = null;
  }
}

void main() {
  group('GenerateApiKeyUsecase', () {
    late GenerateApiKeyUsecase usecase;
    late InMemoryApiKeyRepository repository;

    setUp(() {
      repository = InMemoryApiKeyRepository();
      usecase = GenerateApiKeyUsecase(repository);
    });

    test('deve gerar API key com sucesso', () async {
      // Arrange
      const accountId = 123;
      const keyName = 'test-key';

      // Act
      final result = await usecase.execute(
        accountId: accountId,
        keyName: keyName,
      );

      // Assert
      expect(result.name, equals(keyName));
      expect(result.plainKey, startsWith('sb_live_'));

      final savedKeys = await repository.findAllByAccountId(accountId);
      expect(savedKeys, isNotEmpty);

      final savedKey = savedKeys.first;
      expect(savedKey.name, equals(keyName));
      expect(savedKey.prefix, equals('sb_live_'));
      expect(savedKey.keyHash, isNotNull);
      expect(savedKey.keyHash.length, equals(64)); // SHA-256 hex length
    });

    test('deve gerar keys diferentes em múltiplas chamadas', () async {
      const accountId = 123;

      final result1 = await usecase.execute(
        accountId: accountId,
        keyName: 'key-1',
      );
      final result2 = await usecase.execute(
        accountId: accountId,
        keyName: 'key-2',
      );

      expect(result1.plainKey, isNot(equals(result2.plainKey)));
    });

    test('deve propagar exceção quando o repositório falhar', () async {
      // Arrange
      repository.exceptionToThrow = Exception('Database error');

      // Act & Assert
      expect(
        () => usecase.execute(accountId: 123, keyName: 'test-key'),
        throwsA(isA<Exception>()),
      );
    });

    test('deve gerar chave com formato correto', () async {
      final result = await usecase.execute(
        accountId: 123,
        keyName: 'format-test',
      );

      // Verifica prefixo e se o restante contém caracteres alfanuméricos/base64-safe
      expect(result.plainKey, matches(RegExp(r'^sb_live_[A-Za-z0-9_-]+$')));
    });
  });
}
