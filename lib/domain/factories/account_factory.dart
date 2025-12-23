import 'package:sambura_core/domain/entities/account_entity.dart';
import 'package:sambura_core/application/ports/hash_port.dart';

/// Factory para criação de AccountEntity.
/// 
/// Encapsula a lógica de criação de contas, garantindo que
/// senhas sejam hasheadas corretamente e validações sejam aplicadas.
class AccountFactory {
  final IHashPort _hashPort;

  AccountFactory(this._hashPort);

  /// Cria uma nova conta com senha hasheada.
  /// 
  /// [username] - Nome de usuário único
  /// [password] - Senha em texto plano (será hasheada)
  /// [email] - Email do usuário
  /// [role] - Papel do usuário (admin, developer)
  Future<AccountEntity> create({
    required String username,
    required String password,
    required String email,
    String role = 'developer',
  }) async {
    // Validações
    if (username.isEmpty || username.length < 3) {
      throw ArgumentError('Username must be at least 3 characters');
    }

    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
    }

    if (!email.contains('@')) {
      throw ArgumentError('Invalid email format');
    }

    if (role != 'admin' && role != 'developer') {
      throw ArgumentError('Invalid role. Must be admin or developer');
    }

    // Hasheia a senha usando o hash port
    final passwordHash = _hashPort.hashPassword(password);

    // Cria a entidade
    return AccountEntity(
      username: username,
      passwordHash: passwordHash,
      email: email,
      role: role,
      createdAt: DateTime.now().toUtc(),
    );
  }

  /// Reconstrói uma conta a partir dos dados do banco.
  static AccountEntity fromDatabase(Map<String, dynamic> row) {
    return AccountEntity(
      id: row['id'] as int?,
      username: row['username'] as String,
      passwordHash: row['password_hash'] as String,
      email: row['email'] as String,
      role: row['role'] as String,
      createdAt: row['created_at'] is DateTime
          ? row['created_at'] as DateTime
          : DateTime.parse(row['created_at'] as String),
      lastLoginAt: row['last_login_at'] != null
          ? (row['last_login_at'] is DateTime
              ? row['last_login_at'] as DateTime
              : DateTime.parse(row['last_login_at'] as String))
          : null,
    );
  }

  /// Atualiza o hash da senha de uma conta existente.
  Future<AccountEntity> updatePassword({
    required AccountEntity account,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
    }

    final newPasswordHash = _hashPort.hashPassword(newPassword);

    return AccountEntity(
      id: account.id,
      username: account.username,
      passwordHash: newPasswordHash,
      email: account.email,
      role: account.role,
      createdAt: account.createdAt,
      lastLoginAt: account.lastLoginAt,
    );
  }
}
