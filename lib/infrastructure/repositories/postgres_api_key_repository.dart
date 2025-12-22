import 'package:postgres/postgres.dart';
import 'package:sambura_core/domain/entities/api_key_entity.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';

class PostgresApiKeyRepository implements ApiKeyRepository {
  final PostgresConnector _connector;

  PostgresApiKeyRepository(this._connector);

  Future<void> create({
    required int accountId,
    required String name,
    required String keyHash,
    required String prefix,
    DateTime? expiresAt,
  }) async {
    final query = Sql.named('''
      INSERT INTO api_keys (account_id, name, key_hash, prefix, expires_at)
      VALUES (@accountId, @name, @keyHash, @prefix, @expiresAt)
    ''');

    await _connector.connection.execute(
      query,
      parameters: {
        'accountId': accountId,
        'name': name,
        'keyHash': keyHash,
        'prefix': prefix,
        'expiresAt': expiresAt?.toIso8601String(),
      },
    );
  }

  Future<ApiKeyEntity?> findByHash(String hash) async {
    final query = Sql.named('''
      SELECT id, account_id, name, key_hash, prefix, last_used_at, expires_at 
      FROM api_keys 
      WHERE key_hash = @hash
    ''');

    final result = await _connector.connection.execute(
      query,
      parameters: {'hash': hash},
    );

    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();

    return ApiKeyEntity(
      id: row['id'] as int,
      accountId: row['account_id'] as int,
      name: row['name'] as String,
      keyHash: row['key_hash'] as String,
      prefix: row['prefix'] as String,
      lastUsedAt: row['last_used_at'] as DateTime?,
      expiresAt: row['expires_at'] as DateTime?,
    );
  }

  Future<void> updateLastUsed(int id) async {
    final query = Sql.named('''
      UPDATE api_keys 
      SET last_used_at = NOW() 
      WHERE id = @id
    ''');

    await _connector.connection.execute(query, parameters: {'id': id});
  }

  Future<List<ApiKeyEntity>> findAllByAccount(int accountId) async {
    final query = Sql.named(
      'SELECT * FROM api_keys WHERE account_id = @accountId',
    );

    final result = await _connector.connection.execute(
      query,
      parameters: {'accountId': accountId},
    );

    return result.map((row) {
      final map = row.toColumnMap();
      return ApiKeyEntity(
        id: map['id'] as int,
        accountId: map['account_id'] as int,
        name: map['name'] as String,
        keyHash: map['key_hash'] as String,
        prefix: map['prefix'] as String,
        lastUsedAt: map['last_used_at'] as DateTime?,
        expiresAt: map['expires_at'] as DateTime?,
      );
    }).toList();
  }

  Future<void> delete(int id) async {
    final query = Sql.named('DELETE FROM api_keys WHERE id = @id');
    await _connector.connection.execute(query, parameters: {'id': id});
  }
}
