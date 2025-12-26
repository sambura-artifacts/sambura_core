import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/entities/api_key_entity.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';

class PostgresApiKeyRepository implements ApiKeyRepository {
  final PostgresConnector _connector;
  final Logger _log = LoggerConfig.getLogger('PostgresApiKeyRepository');

  PostgresApiKeyRepository(this._connector);

  @override
  Future<void> create({
    required int accountId,
    required String name,
    required String keyHash,
    required String prefix,
    DateTime? expiresAt,
  }) async {
    _log.info(
      'Criando API key: accountId=$accountId, name=$name, prefix=$prefix',
    );

    try {
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

      _log.info('✓ API key criada com sucesso no banco');
    } catch (e, stack) {
      _log.severe('✗ Erro ao criar API key no banco', e, stack);
      rethrow;
    }
  }

  @override
  Future<ApiKeyEntity?> findByHash(String hash) async {
    _log.fine('Buscando API key por hash');

    try {
      final query = Sql.named('''
      SELECT id, account_id, name, key_hash, prefix, last_used_at, expires_at 
      FROM api_keys 
      WHERE key_hash = @hash
    ''');

      final result = await _connector.connection.execute(
        query,
        parameters: {'hash': hash},
      );

      if (result.isEmpty) {
        _log.fine('API key não encontrada');
        return null;
      }

      final row = result.first.toColumnMap();
      _log.fine(
        'API key encontrada: name=${row['name']}, prefix=${row['prefix']}',
      );

      return ApiKeyEntity(
        id: row['id'] as int,
        accountId: row['account_id'] as int,
        name: row['name'] as String,
        keyHash: row['key_hash'] as String,
        prefix: row['prefix'] as String,
        lastUsedAt: row['last_used_at'] as DateTime?,
        expiresAt: row['expires_at'] as DateTime?,
      );
    } catch (e, stack) {
      _log.severe('✗ Erro ao buscar API key por hash', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> updateLastUsed(int id) async {
    _log.fine('Atualizando last_used_at para API key: id=$id');

    try {
      final query = Sql.named('''
      UPDATE api_keys 
      SET last_used_at = NOW() 
      WHERE id = @id
    ''');

      await _connector.connection.execute(query, parameters: {'id': id});
      _log.fine('✓ last_used_at atualizado');
    } catch (e, stack) {
      _log.severe(
        '✗ Erro ao atualizar last_used_at da API key: id=$id',
        e,
        stack,
      );
      rethrow;
    }
  }

  @override
  Future<List<ApiKeyEntity>> findAllByAccountId(int accountId) async {
    _log.fine('Listando API keys do account: accountId=$accountId');

    try {
      final query = 'SELECT * FROM api_keys WHERE account_id = @accountId';

      final result = await _connector.query(
        query,
        substitutionValues: {'accountId': accountId},
      );

      print("affectedRows: ${result.affectedRows}");

      final keys = result.map((row) {
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

      _log.info(
        '✓ ${keys.length} API keys encontradas para accountId=$accountId',
      );
      return keys;
    } catch (e, stack) {
      _log.severe(
        '✗ Erro ao listar API keys do account: accountId=$accountId',
        e,
        stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> delete(int id) async {
    _log.info('Deletando API key: id=$id');

    try {
      final query = Sql.named('DELETE FROM api_keys WHERE id = @id');
      await _connector.connection.execute(query, parameters: {'id': id});
      _log.info('✓ API key deletada com sucesso');
    } catch (e, stack) {
      _log.severe('✗ Erro ao deletar API key: id=$id', e, stack);
      rethrow;
    }
  }

  @override
  Future<ApiKeyEntity> findByAccountId(int accountId) async {
    final sql = '''
    SELECT * FROM api_keys WHERE account_id = @account_id
    ''';

    try {
      final result = await _connector.query(
        sql,
        substitutionValues: {'account_id': accountId},
      );

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
    } catch (e, stack) {
      _log.severe('✗ Erro ao buscar API key: id=$accountId', e, stack);
      rethrow;
    }
  }
}
