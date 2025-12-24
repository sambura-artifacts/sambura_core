import 'package:sambura_core/domain/entities/account_entity.dart';

/// Factory para criar instâncias de AccountEntity
class AccountFactory {
  /// Cria uma nova conta para cadastro
  static AccountEntity create({
    required String username,
    required String password,
    required String email,
    String role = 'developer',
  }) {
    return AccountEntity.create(
      username: username,
      password: password,
      email: email,
      role: role,
    );
  }

  static AccountEntity restore({
    required int id,
    required String externalId,
    required String username,
    required String password,
    required String email,
    required String role,
    required DateTime createdAt,
    DateTime? lastLoginAt,
  }) {
    return AccountEntity.restore(
      id: id,
      externalId: externalId,
      username: username,
      password: password,
      email: email,
      role: role,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }
}
