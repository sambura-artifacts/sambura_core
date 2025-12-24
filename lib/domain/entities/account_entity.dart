import 'package:sambura_core/domain/value_objects/email.dart';
import 'package:sambura_core/domain/value_objects/external_id.dart';
import 'package:sambura_core/domain/value_objects/password.dart';
import 'package:sambura_core/domain/value_objects/role.dart';
import 'package:sambura_core/domain/value_objects/username.dart';

class AccountEntity {
  final int? id;
  final ExternalId externalId;
  final Username username; // Use final para imutabilidade da entidade
  final Password password;
  final Email email;
  final Role role;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  AccountEntity._({
    this.id,
    required this.externalId,
    required this.username,
    required this.password,
    required this.email,
    required this.role,
    this.createdAt,
    this.lastLoginAt,
  });

  // Factory para novos cadastros (Username e Password brutos)
  factory AccountEntity.create({
    required String username,
    required String password,
    required String email,
    String role = Role.developer,
  }) {
    return AccountEntity._(
      externalId: ExternalId.generate(), // Assume que você tem um .generate()
      username: Username(username),
      password: Password(password),
      email: Email(email),
      role: Role(role),
      createdAt: DateTime.now(),
    );
  }

  // Factory para reconstruir do Banco de Dados (Dados já validados)
  factory AccountEntity.restore({
    required int id,
    required String externalId,
    required String username,
    required String password, // Nomeado para clareza
    required String email,
    required String role,
    required DateTime createdAt,
    DateTime? lastLoginAt,
  }) {
    return AccountEntity._(
      id: id,
      externalId: ExternalId(externalId),
      username: Username(username),
      password: Password(password), // No restore, o VO Password aceita o hash
      email: Email(email),
      role: Role(role),
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  // Método de atualização seguindo imutabilidade
  AccountEntity changePassword(String newHashedPassword) {
    return AccountEntity._(
      id: id,
      externalId: externalId,
      username: username,
      password: Password(newHashedPassword),
      email: email,
      role: role,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  // Getters simplificados
  bool get isAdmin => role.isAdmin;
  String get passwordHash => password.value;
  String get usernameValue => username.value;
  String get externalIdValue => externalId.value;
  String get roleValue => role.value;
}
