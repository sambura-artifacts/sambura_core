import 'package:sambura_core/application/usecase/account/create_account_usecase.dart';
import 'package:sambura_core/domain/entities/account_entity.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';
import 'package:sambura_core/infrastructure/services/auth/hash_service.dart';
import 'package:test/test.dart';

// Implementação InMemory para testes consistentes
class InMemoryAccountRepository implements AccountRepository {
  final List<AccountEntity> _storage = [];
  Exception? exceptionToThrow;

  @override
  Future<AccountEntity?> create(AccountEntity account) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    _storage.add(account);
    return account;
  }

  // Helpers para o Assert
  bool get createCalled => _storage.isNotEmpty;
  AccountEntity? get lastCreatedAccount =>
      _storage.isEmpty ? null : _storage.last;

  Future<AccountEntity?> findByEmail(String email) async => null;
  @override
  Future<AccountEntity?> findByExternalId(String externalId) async => null;
  @override
  Future<AccountEntity?> findById(int id) async => null;
  @override
  Future<AccountEntity?> findByUsername(String username) async => null;
  Future<void> update(AccountEntity account) async {}
}

class MockHashService implements HashService {
  String hashToReturn = 'Hashed@Pass123!';
  @override
  String hashPassword(String password) => hashToReturn;
  @override
  bool verify(String password, String hash) => true;
}

void main() {
  group('CreateAccountUsecase', () {
    late CreateAccountUsecase usecase;
    late InMemoryAccountRepository repository;
    late MockHashService hashService;

    // Senha com alta entropia para evitar PasswordException
    const strongPassword = 'Complex@Password#2025!ExtraChars';

    setUp(() {
      repository = InMemoryAccountRepository();
      hashService = MockHashService();
      usecase = CreateAccountUsecase(repository, hashService);
    });

    test('deve criar conta com sucesso', () async {
      const username = 'testuser';
      const email = 'test@example.com';

      await usecase.execute(
        username: username,
        password: strongPassword,
        email: email,
      );

      expect(repository.createCalled, isTrue);
      expect(repository.lastCreatedAccount!.username.value, equals(username));
      expect(repository.lastCreatedAccount!.email.value, equals(email));
      expect(
        repository.lastCreatedAccount!.password.value,
        equals('Hashed@Pass123!'),
      );
    });

    test('deve criar conta com role padrão "developer"', () async {
      await usecase.execute(
        username: 'testuser',
        password: strongPassword,
        email: 'test@example.com',
      );

      expect(repository.lastCreatedAccount!.role.value, equals('developer'));
    });

    test('deve criar conta com role personalizada', () async {
      const role = 'admin';

      await usecase.execute(
        username: 'adminuser',
        password: strongPassword,
        email: 'admin@example.com',
        role: role,
      );

      expect(repository.lastCreatedAccount!.role.value, equals(role));
    });

    test('deve propagar exceção quando repositório falhar', () async {
      repository.exceptionToThrow = Exception('Database error');

      expect(
        () => usecase.execute(
          username: 'testuser',
          password: strongPassword,
          email: 'test@example.com',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
