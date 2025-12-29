import 'package:sambura_core/application/auth/ports/ports.dart';
import 'package:sambura_core/application/auth/login/usecase/login_usecase.dart';
import 'package:sambura_core/domain/account/entity/account_entity.dart';
import 'package:sambura_core/domain/account/repository/account_repository.dart';
import 'package:sambura_core/infrastructure/infrastructure.dart';
import 'package:test/test.dart';

class InMemoryAccountRepository implements AccountRepository {
  // Simula a tabela do banco de dados em memória
  final Map<String, AccountEntity> _accounts = {};

  // Controle para simular erros em testes de falha
  bool shouldThrowError = false;

  void _checkError() {
    if (shouldThrowError) throw Exception('Database error');
  }

  @override
  Future<AccountEntity?> create(AccountEntity account) async {
    _checkError();
    // Armazena usando o username como chave (ou ID, dependendo da sua lógica)
    _accounts[account.username.value] = account;
    return account;
  }

  @override
  Future<AccountEntity?> findByUsername(String username) async {
    _checkError();
    return _accounts[username];
  }

  @override
  Future<AccountEntity?> findByEmail(String email) async {
    _checkError();
    try {
      return _accounts.values.firstWhere((acc) => acc.email.value == email);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AccountEntity?> findByExternalId(String externalId) async {
    _checkError();
    try {
      return _accounts.values.firstWhere(
        (acc) => acc.externalId.value == externalId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AccountEntity?> findById(int id) async {
    _checkError();
    return _accounts.values.firstWhere(
      (acc) => acc.id == id,
      orElse: () => null as dynamic,
    );
  }

  @override
  Future<bool> existsByRole(String role) async {
    _checkError();
    return _accounts.values.any((acc) => acc.role.value == role);
  }

  // Helper para limpar o repositório entre os testes
  void clear() => _accounts.clear();
}

void main() {
  group('LoginUsecase', () {
    late LoginUsecase usecase;
    late InMemoryAccountRepository repository; // Alterado para o tipo concreto
    late HashPort hashService;
    const String pepper = 'teste_pepper';
    const jwtSecret = 'test-secret-key';

    setUp(() {
      repository = InMemoryAccountRepository();
      hashService = BcryptHashAdapter(pepper);
      usecase = LoginUsecase(repository, hashService, jwtSecret);
    });

    test('deve retornar token quando credenciais são válidas', () async {
      // Arrange
      const username = 'testuser';
      const password = 'password123@312CCCCC';

      // Persistimos a conta de verdade no repositório in-memory
      final account = AccountEntity.restore(
        id: 1,
        externalId: '3ef0cb03-9f2c-4c01-90bc-329cd3555ebe',
        username: username,
        email: 'test@example.com',
        password: hashService.hashPassword(password), // Hash real para validar
        role: 'developer',
        createdAt: DateTime.now(),
      );
      await repository.create(account);

      // Act
      final result = await usecase.execute(username, password);

      // Assert
      expect(result, isNotNull);
      expect(result!.username, equals(username));
      expect(result.token, startsWith('eyJ'));
    });

    test('deve retornar null quando usuário não existe', () async {
      // Arrange - Repositório vazio
      const username = 'nonexistent';
      const password = 'password123';

      // Act
      final result = await usecase.execute(username, password);

      // Assert
      expect(result, isNull);
    });

    test('deve retornar null quando senha é inválida', () async {
      // Arrange
      const username = 'testuser';
      const correctPassword = 'password_correta';
      const wrongPassword = 'senha_errada';

      final account = AccountEntity.restore(
        id: 1,
        externalId: '3ef0cb03-9f2c-4c01-90bc-329cd3555ebe',
        username: username,
        email: 'test@example.com',
        password: hashService.hashPassword(correctPassword),
        role: 'developer',
        createdAt: DateTime.now(),
      );
      await repository.create(account);

      // Act
      final result = await usecase.execute(username, wrongPassword);

      // Assert
      expect(result, isNull);
    });

    test('deve propagar exceção quando ocorre erro no repositório', () async {
      repository.shouldThrowError = true;

      expect(() => usecase.execute('any', 'any'), throwsA(isA<Exception>()));
    });
  });
}
