import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/package_repository.dart';
import 'package:sambura_core/domain/entities/package_entity.dart';
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';

class PostgresPackageRepository implements PackageRepository {
  final PostgresConnector _db;
  final Logger _log = LoggerConfig.getLogger('PostgresPackageRepository');

  PostgresPackageRepository(this._db);

  @override
  Future<List<PackageEntity>> listByRepositoryName(
    String repoName, {
    int limit = 20,
    int offset = 0,
  }) async {
    _log.fine(
      'Listando pacotes do repo: $repoName (limit=$limit, offset=$offset)',
    );
    try {
      final res = await _db.connection.execute(
        Sql.named(
          'SELECT p.* FROM packages p '
          'INNER JOIN repositories r ON p.repository_id = r.id '
          'WHERE r.name = @repoName '
          'ORDER BY p.name ASC '
          'LIMIT @limit OFFSET @offset',
        ),
        parameters: {'repoName': repoName, 'limit': limit, 'offset': offset},
      );

      _log.info('Encontrados ${res.length} pacotes no repo $repoName');
      return res
          .map((row) => PackageEntity.fromMap(row.toColumnMap()))
          .toList();
    } catch (e, stackTrace) {
      _log.severe('Erro ao listar pacotes por repo: $repoName', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<PackageEntity> ensurePackage({
    required int repositoryId,
    required String name,
  }) async {
    _log.fine('EnsurePackage: $name no repo_id: $repositoryId');
    try {
      final result = await _db.connection.execute(
        Sql.named(
          'INSERT INTO packages (repository_id, name, created_at) '
          'VALUES (@repositoryId, @name, NOW()) '
          'ON CONFLICT (repository_id, name) DO UPDATE SET name = EXCLUDED.name '
          'RETURNING *',
        ),
        parameters: {'repositoryId': repositoryId, 'name': name},
      );

      if (result.isEmpty) {
        throw Exception(
          "Falha no ensurePackage: O banco não retornou dados para $name",
        );
      }

      final package = PackageEntity.fromMap(result.first.toColumnMap());
      _log.info('Pacote garantido: ID ${package.id}, name=$name');
      return package;
    } catch (e, stackTrace) {
      _log.severe('Erro no ensurePackage: $name', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<PackageEntity?> findByName(int repositoryId, String name) async {
    try {
      final res = await _db.connection.execute(
        Sql.named(
          'SELECT * FROM packages WHERE repository_id = @repoId AND name = @name LIMIT 1',
        ),
        parameters: {'repoId': repositoryId, 'name': name},
      );
      if (res.isEmpty) return null;
      return PackageEntity.fromMap(res.first.toColumnMap());
    } catch (e, stackTrace) {
      _log.severe('Erro no findByName: $name', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<PackageEntity?> findByGlobalName(String name) async {
    try {
      final res = await _db.connection.execute(
        Sql.named('SELECT * FROM packages WHERE name = @name LIMIT 1'),
        parameters: {'name': name},
      );
      if (res.isEmpty) return null;
      return PackageEntity.fromMap(res.first.toColumnMap());
    } catch (e, stackTrace) {
      _log.severe('Erro no findByGlobalName: $name', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<PackageEntity>> listByNamespace(
    String namespace, {
    int limit = 50,
    int offset = 0,
  }) async {
    _log.fine('Listando por namespace: $namespace');

    final sql = '''
      SELECT p.* FROM packages p JOIN repositories r ON p.repository_id = r.id 
      WHERE r.namespace = @namespace
      LIMIT @limit OFFSET @offset
    ''';

    try {
      final res = await _db.query(sql, {
        'namespace': namespace,
        'limit': limit,
        'offset': offset,
      });

      _log.info('Encontrados ${res.length} pacotes no namespace $namespace');

      return res
          .map((row) => PackageEntity.fromMap(row.toColumnMap()))
          .toList();
    } catch (e, stackTrace) {
      _log.severe('Erro ao listar por namespace: $namespace', e, stackTrace);

      rethrow;
    }
  }

  @override
  Future<List<PackageEntity>> listAll({int limit = 50, int offset = 0}) async {
    const sql = '''
    SELECT * FROM packages 
    ORDER BY created_at DESC 
    LIMIT @limit OFFSET @offset
  ''';

    try {
      final result = await _db.connection.execute(
        sql,
        parameters: {'limit': limit, 'offset': offset},
      );

      return result
          .map((row) => PackageEntity.fromMap(row.toColumnMap()))
          .toList();
    } catch (e, stack) {
      _log.severe('🔥 Erro ao listar pacotes com fromMap', e, stack);
      rethrow;
    }
  }

  @override
  Future<List<PackageEntity>> findByRepositoryNameAndPackageName(
    String repoName,
    String packageName,
  ) async {
    const sql = '''
      SELECT p.id, p.repository_id, p.name, p.description, p.created_at 
      FROM packages p
      INNER JOIN repositories r ON p.repository_id = r.id
      WHERE r.name = @repoName 
        AND p.name = @packageName
    ''';

    final result = await _db.query(sql, {
      'repoName': repoName,
      'packageName': packageName,
    });

    return result.map((row) {
      final data = row.toColumnMap();

      return PackageEntity.restore(
        data['id'] as int,
        data['repository_id'] as int,
        data['name'] as String,
        data['description'] ?? '',
        data['created_at'] as DateTime,
      );
    }).toList();
  }
}
