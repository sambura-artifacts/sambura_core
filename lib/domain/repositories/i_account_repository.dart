import 'package:sambura_core/domain/entities/account_entity.dart';

/// Interface para operações de escrita de contas.
abstract class IAccountWriteRepository {
  /// Cria uma nova conta.
  Future<AccountEntity> save(AccountEntity account);

  /// Atualiza uma conta existente.
  Future<AccountEntity> update(AccountEntity account);

  /// Remove uma conta (soft delete).
  Future<void> delete(int accountId);
}

/// Interface para operações de leitura de contas.
abstract class IAccountReadRepository {
  /// Busca conta por ID.
  Future<AccountEntity?> findById(int id);

  /// Busca conta por username.
  Future<AccountEntity?> findByUsername(String username);

  /// Busca conta por email.
  Future<AccountEntity?> findByEmail(String email);

  /// Verifica se username existe.
  Future<bool> usernameExists(String username);

  /// Verifica se email existe.
  Future<bool> emailExists(String email);

  /// Lista todas as contas (com paginação).
  Future<List<AccountEntity>> findAll({
    int limit = 50,
    int offset = 0,
  });
}

/// Interface para consultas de autenticação.
abstract class IAccountAuthRepository {
  /// Busca credenciais para autenticação.
  Future<AccountEntity?> findByCredentials({
    required String username,
    required String passwordHash,
  });

  /// Atualiza último login.
  Future<void> updateLastLogin(int accountId);

  /// Lista contas por role.
  Future<List<AccountEntity>> findByRole(String role);
}
