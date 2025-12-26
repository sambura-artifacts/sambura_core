import 'package:sambura_core/domain/entities/account_entity.dart';

class AccountMapper {
  /// Converte a Entidade para um Map (para salvar no Redis/JSON)
  static Map<String, dynamic> toMap(AccountEntity account) {
    return {
      'id': account.id,
      'external_id': account.externalId.value,
      'username': account.username.value,
      'email': account.email.value,
      'role': account.role.value,
    };
  }

  static Map<String, dynamic> toMapFull(AccountEntity account) {
    return {
      'id': account.id as int,
      'external_id': account.externalId.value,
      'username': account.username.value,
      'password': account.password!.value,
      'email': account.email.value,
      'role': account.role.value,
      'created_at': account.createdAt,
      'last_login': account.lastLoginAt,
    };
  }

  /// Converte o Map vindo do Redis/DB de volta para a Entidade
  static AccountEntity fromMap(Map<String, dynamic> map) {
    return AccountEntity.restore(
      id: map['id'] as int?,
      externalId: map['external_id'] as String,
      username: map['username'] as String,
      password: map['password'] as String?,
      email: map['email'] as String,
      role: map['role'] as String,
      createdAt: map['created_at'] as DateTime,
      lastLoginAt: map['last_login'] as DateTime?,
    );
  }
}
