import 'package:sambura_core/domain/entities/api_key_entity.dart';

/// Factory para criar instâncias de ApiKeyEntity
class ApiKeyFactory {
  /// Cria uma nova API key
  static ApiKeyEntity create({
    required int accountId,
    required String name,
    required String keyHash,
    required String prefix,
    DateTime? expiresAt,
  }) {
    return ApiKeyEntity(
      accountId: accountId,
      name: name,
      keyHash: keyHash,
      prefix: prefix,
      createdAt: DateTime.now().toUtc(),
      expiresAt: expiresAt,
    );
  }

  /// Reconstrói uma API key a partir do banco de dados
  static ApiKeyEntity restore({
    required int id,
    required int accountId,
    required String name,
    required String keyHash,
    required String prefix,
    required DateTime createdAt,
    DateTime? lastUsedAt,
    DateTime? expiresAt,
  }) {
    return ApiKeyEntity(
      id: id,
      accountId: accountId,
      name: name,
      keyHash: keyHash,
      prefix: prefix,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt,
      expiresAt: expiresAt,
    );
  }
}
