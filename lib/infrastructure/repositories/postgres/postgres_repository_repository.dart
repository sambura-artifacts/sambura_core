import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/entities/repository_entity.dart';
import 'package:sambura_core/domain/repositories/repository_repository.dart';
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';

class PostgresRepositoryRepository implements RepositoryRepository {
  final PostgresConnector _db;
  final Logger _log = LoggerConfig.getLogger('PostgresRepositoryRepository');

  PostgresRepositoryRepository(this._db);

  @override
  Future<List<RepositoryEntity>> list({int limit = 10, int offset = 0}) async {
    try {
      final result = await _db.query(
        'SELECT * FROM repositories ORDER BY created_at DESC LIMIT @limit OFFSET @offset',
        substitutionValues: {'limit': limit, 'offset': offset},
      );
      return result
          .map((row) => RepositoryEntity.fromMap(row.toColumnMap()))
          .toList();
    } catch (e, stackTrace) {
      _log.severe('Erro na listagem de repositórios', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<RepositoryEntity?> getByName(String name) async {
    try {
      final result = await _db.query(
        'SELECT * FROM repositories WHERE name = @name',
        substitutionValues: {'name': name},
      );
      if (result.isEmpty) return null;
      return RepositoryEntity.fromMap(result.first.toColumnMap());
    } catch (e, stackTrace) {
      _log.severe('Erro ao buscar repositório por nome: $name', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<RepositoryEntity>> listByNamespace(String namespace) async {
    try {
      final result = await _db.query(
        'SELECT * FROM repositories WHERE namespace = @namespace',
        substitutionValues: {'namespace': namespace},
      );
      return result
          .map((row) => RepositoryEntity.fromMap(row.toColumnMap()))
          .toList();
    } catch (e, stackTrace) {
      _log.severe('Erro ao listar por namespace: $namespace', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<RepositoryEntity> save(RepositoryEntity repository) async {
    _log.fine(
      'Salvando: name=${repository.name}, namespace=${repository.namespace}, public=${repository.isPublic}',
    );

    try {
      // Garante que o SQL e os parâmetros estão batendo certinho
      final sql = '''
        INSERT INTO repositories (name, namespace, is_public) 
        VALUES (@name, @namespace, @is_public) 
        ON CONFLICT (name) DO UPDATE SET 
          namespace = EXCLUDED.namespace, 
          is_public = EXCLUDED.is_public 
        RETURNING id, name, namespace, is_public, created_at
      ''';

      final result = await _db.query(
        sql,
        substitutionValues: {
          'name': repository.name,
          'namespace': repository.namespace,
          'is_public': repository.isPublic,
        },
      );

      if (result.isEmpty) throw Exception("Linha vazia no retorno");

      final row = result.first.toColumnMap();
      final saved = RepositoryEntity.fromMap(row);
      _log.info('Repositório salvo: ID=${saved.id}, name=${saved.name}');
      return saved;
    } catch (e, stackTrace) {
      _log.severe('Erro ao salvar repositório', e, stackTrace);
      rethrow;
    }
  }
}
