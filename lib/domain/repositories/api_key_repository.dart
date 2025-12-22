import 'package:sambura_core/domain/entities/api_key_entity.dart';

abstract class ApiKeyRepository {
  Future<void> create({
    required int accountId,
    required String name,
    required String keyHash,
    required String prefix,
    DateTime? expiresAt,
  });

  Future<ApiKeyEntity?> findByHash(String hash);

  Future<List<ApiKeyEntity>> findAllByAccount(int accountId);

  Future<void> updateLastUsed(int id);

  Future<void> delete(int id);
}
