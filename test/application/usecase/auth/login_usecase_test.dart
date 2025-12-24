import 'package:sambura_core/application/usecase/auth/login_usecase.dart';
import 'package:sambura_core/domain/entities/account_entity.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';
import 'package:sambura_core/infrastructure/services/auth/hash_service.dart';
import 'package:test/test.dart';

class MockAccountRepository implements AccountRepository {
  AccountEntity? accountToReturn;

  @override
  Future<AccountEntity?> findByUsername(String username) async {
    return accountToReturn;
  }

  @override
  Future<AccountEntity?> create(AccountEntity account) async {
    throw UnimplementedError();
  }

  Future<AccountEntity?> findByEmail(String email) async {
    throw UnimplementedError();
  }

  @override
  Future<AccountEntity?> findByExternalId(String externalId) async {
    throw UnimplementedError();
  }

  @override
  Future<AccountEntity?> findById(int id) async {
    throw UnimplementedError();
  }

  Future<void> update(AccountEntity account) async {
    throw UnimplementedError();
  }
}

class MockHashService implements HashService {
  bool shouldVerifySucceed = true;

  @override
  String hashPassword(String password) {
    throw UnimplementedError();
  }

  @override
  bool verify(String password, String hash) {
    return shouldVerifySucceed;
  }
}

void main() {
  group('LoginUsecase', () {
    late LoginUsecase usecase;
    late MockAccountRepository repository;
    late MockHashService hashService;
    const jwtSecret = 'test-secret-key';

    setUp(() {
      repository = MockAccountRepository();
      hashService = MockHashService();
      usecase = LoginUsecase(repository, hashService, jwtSecret);
    });

    test('deve retornar token quando credenciais são válidas', () async {
      // Arrange
      const username = 'testuser';
      const password = 'password123';

      final account = AccountEntity.restore(
        id: 1,
        externalId: 'ext-123',
        username: username,
        email: 'test@example.com',
        password: 'hashed_password',
        role: 'developer',
        createdAt: DateTime.now(),
      );

      repository.accountToReturn = account;
      hashService.shouldVerifySucceed = true;

      // Act
      final result = await usecase.execute(username, password);

      // Assert
      expect(result, isNotNull);
      expect(result!.username, equals(username));
      expect(result.token, isNotEmpty);
      expect(result.token, startsWith('eyJ')); // JWT header
    });

    test('deve retornar null quando usuário não existe', () async {
      // Arrange
      const username = 'nonexistent';
      const password = 'password123';
      repository.accountToReturn = null;

      // Act
      final result = await usecase.execute(username, password);

      // Assert
      expect(result, isNull);
    });

    test('deve retornar null quando senha é inválida', () async {
      // Arrange
      const username = 'testuser';
      const password = 'wrongpassword';

      final account = AccountEntity.restore(
        id: 1,
        externalId: '01234567-89ab-cdef-0123-456789abcdef',
        username: username,
        email: 'test@example.com',
        password: 'hashed_password',
        role: 'developer',
        createdAt: DateTime.now(),
      );

      repository.accountToReturn = account;
      hashService.shouldVerifySucceed = false;

      // Act
      final result = await usecase.execute(username, password);

      // Assert
      expect(result, isNull);
    });

    test('deve incluir informações corretas no token JWT', () async {
      // Arrange
      const username = 'testuser';
      const password = 'password123';

      final account = AccountEntity.restore(
        id: 42,
        externalId: '01234567-89ab-cdef-0123-456789abcdef',
        username: username,
        email: 'test@example.com',
        password: 'hashed_password',
        role: 'admin',
        createdAt: DateTime.now(),
      );

      repository.accountToReturn = account;
      hashService.shouldVerifySucceed = true;

      // Act
      final result = await usecase.execute(username, password);

      // Assert
      expect(result, isNotNull);
      expect(result!.token, isNotEmpty);
      // JWT contém 3 partes separadas por ponto
      expect(result.token.split('.'), hasLength(3));
    });

    test('deve propagar exceção quando repositório falhar', () async {
      // Arrange
      const username = 'testuser';
      const password = 'password123';

      repository.accountToReturn = null;

      // Act
      final result = await usecase.execute(username, password);

      // Assert
      expect(result, isNull);
    });
  });
}
