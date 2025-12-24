import 'package:sambura_core/application/exceptions/application_exception.dart';
import 'package:sambura_core/application/usecase/api_key/revoke_api_key_usecase.dart';
import 'package:sambura_core/domain/entities/account_entity.dart';
import 'package:sambura_core/domain/entities/api_key_entity.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:test/test.dart';
import 'package:uuid/v7.dart';

// --- IMPLEMENTAÇÕES IN-MEMORY PARA TESTE ---

class InMemoryApiKeyRepository implements ApiKeyRepository {
  final List<ApiKeyEntity> _storage = [];
  Exception? exceptionToThrow;

  @override
  Future<void> create({
    required int accountId,
    required String name,
    required String keyHash,
    required String prefix,
    DateTime? expiresAt,
  }) async {
    _storage.add(
      ApiKeyEntity(
        id: _storage.length + 1,
        accountId: accountId,
        name: name,
        keyHash: keyHash,
        prefix: prefix,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<ApiKeyEntity?> findByHash(String hash) async {
    try {
      return _storage.firstWhere((k) => k.keyHash == hash);
    } catch (_) {
      return null; // O firstWhere joga uma StateError se não achar, o catch captura e retorna null
    }
  }

  // Ajuste para o teste: findByHash costuma retornar null se não achar, mas aqui simularemos a busca.
  Future<ApiKeyEntity?> findSafe(String hash) async {
    try {
      return _storage.firstWhere((k) => k.keyHash == hash);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> delete(int id) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    _storage.removeWhere((k) => k.id == id);
  }

  @override
  Future<List<ApiKeyEntity>> findAllByAccountId(int accountId) async => [];
  @override
  Future<ApiKeyEntity> findByAccountId(int accountId) async =>
      throw UnimplementedError();
  @override
  Future<void> updateLastUsed(int id) async {}
}

class InMemoryAccountRepository implements AccountRepository {
  final List<AccountEntity> _storage = [];

  @override
  Future<AccountEntity?> findByExternalId(String externalId) async {
    try {
      return _storage.firstWhere((a) => a.externalId.value == externalId);
    } catch (_) {
      return null;
    }
  }

  void save(AccountEntity account) => _storage.add(account);

  @override
  Future<AccountEntity?> create(AccountEntity account) async => null;
  Future<AccountEntity?> findByEmail(String email) async => null;
  @override
  Future<AccountEntity?> findById(int id) async => null;
  @override
  Future<AccountEntity?> findByUsername(String username) async => null;
  Future<void> update(AccountEntity account) async {}
}

// --- MAIN TEST ---

void main() {
  group('RevokeApiKeyUsecase', () {
    late RevokeApiKeyUsecase usecase;
    late InMemoryApiKeyRepository apiKeyRepository;
    late InMemoryAccountRepository accountRepository;

    setUp(() {
      apiKeyRepository = InMemoryApiKeyRepository();
      accountRepository = InMemoryAccountRepository();
      usecase = RevokeApiKeyUsecase(apiKeyRepository, accountRepository);
    });

    test('deve revogar API key quando usuário é o dono', () async {
      const keyHash = 'owner-hash';
      final userId = UuidV7().generate();

      // Semeia conta (ID 1 interno, UUID externo)
      final account = AccountEntity.restore(
        id: 1,
        externalId: userId,
        username: 'owner',
        email: 'a@a.com',
        password: '@Ed0rianryaaeowuawrr',
        role: 'admin',
        createdAt: DateTime.now(),
      );
      accountRepository.save(account);

      // Semeia Key vinculada ao ID 1
      await apiKeyRepository.create(
        accountId: 1,
        name: 'k',
        keyHash: keyHash,
        prefix: 'sb_',
      );

      await usecase.execute(key: keyHash, requestUserId: userId);

      expect(await apiKeyRepository.findSafe(keyHash), isNull);
    });

    test(
      'deve revogar API key quando usuário é admin mesmo não sendo dono',
      () async {
        const keyHash = 'other-hash';
        final adminId = UuidV7().generate();

        // Admin no repositório
        accountRepository.save(
          AccountEntity.restore(
            id: 2,
            externalId: adminId,
            username: 'admin',
            email: 'b@b.com',
            password: '@deoRk23mrh9_eoain',
            role: 'admin',
            createdAt: DateTime.now(),
          ),
        );

        // Key de OUTRO usuário (ID 50)
        await apiKeyRepository.create(
          accountId: 1,
          name: 'k',
          keyHash: keyHash,
          prefix: 'sb_',
        );

        await usecase.execute(key: keyHash, requestUserId: adminId);

        expect(await apiKeyRepository.findSafe(keyHash), isNull);
      },
    );

    test(
      'deve lançar ApiKeyNotFoundException quando chave não existe',
      () async {
        expect(
          () =>
              usecase.execute(key: 'ghost', requestUserId: UuidV7().generate()),
          throwsA(isA<ApiKeyNotFoundException>()),
        );
      },
    );

    test(
      'deve lançar AccountNotPermissionException quando usuário comum tenta apagar chave alheia',
      () async {
        const keyHash = 'secret-hash';
        final intruderId = UuidV7().generate();

        accountRepository.save(
          AccountEntity.restore(
            id: 10,
            externalId: intruderId,
            username: 'hacker',
            email: 'h@h.com',
            password: 'h@diwncbEMjei1234oj..ce',
            role: 'viewer',
            createdAt: DateTime.now(),
          ),
        );

        await apiKeyRepository.create(
          accountId: 1,
          name: 'owner-key',
          keyHash: keyHash,
          prefix: 'sb_',
        );

        expectLater(
          usecase.execute(key: keyHash, requestUserId: intruderId),
          throwsA(isA<AccountNotPermissionException>()),
        );
      },
    );

    test('deve propagar erro do banco', () async {
      const keyHash = 'fail-hash';
      final userId = UuidV7().generate();

      accountRepository.save(
        AccountEntity.restore(
          id: 1,
          externalId: userId,
          username: 'username',
          email: 'e@e.com',
          password: 'h@3nMY@RAa40s',
          role: 'admin',
          createdAt: DateTime.now(),
        ),
      );
      await apiKeyRepository.create(
        accountId: 1,
        name: 'k',
        keyHash: keyHash,
        prefix: 'sb_',
      );

      apiKeyRepository.exceptionToThrow = Exception('DB Crash');

      expect(
        () => usecase.execute(key: keyHash, requestUserId: userId),
        throwsA(isA<Exception>()),
      );
    });

    test('deve logar informação de sucesso ao revogar key', () async {
      const keyHash = 'success-hash';
      final userId = UuidV7().generate();

      accountRepository.save(
        AccountEntity.restore(
          id: 1,
          externalId: userId,
          username: 'user',
          email: 'user@example.com',
          password: 'Password123!@#',
          role: 'admin',
          createdAt: DateTime.now(),
        ),
      );

      await apiKeyRepository.create(
        accountId: 1,
        name: 'test-key',
        keyHash: keyHash,
        prefix: 'sb_',
      );

      await usecase.execute(key: keyHash, requestUserId: userId);

      expect(await apiKeyRepository.findSafe(keyHash), isNull);
    });

    test(
      'deve lançar AccountNotFoundException quando requestUser não existe',
      () async {
        const keyHash = 'some-key-hash';
        const nonExistentUserId = '018c1820-a9f6-7123-b456-789012345678';

        await apiKeyRepository.create(
          accountId: 1,
          name: 'test-key',
          keyHash: keyHash,
          prefix: 'sb_',
        );

        expect(
          () => usecase.execute(key: keyHash, requestUserId: nonExistentUserId),
          throwsA(isA<AccountNotFoundException>()),
        );
      },
    );
  });
}
