import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';
import 'package:sambura_core/domain/entities/artifact_entity.dart';
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';

class PostgresArtifactRepository implements ArtifactRepository {
  final PostgresConnector _db;
  final Logger _log = LoggerConfig.getLogger('PostgresArtifactRepository');

  PostgresArtifactRepository(this._db);

  @override
  Future<ArtifactEntity> save(ArtifactEntity artifact) async {
    const sql = '''
    INSERT INTO artifacts (package_id, blob_id, external_id, version, path, created_at) 
    VALUES (@packageId, @blobId, @externalId, @version, @path, @createdAt) 
    RETURNING id
  ''';

    final params = {
      'packageId': artifact.packageId,
      'blobId': artifact.blob!.id,
      'externalId': artifact.externalId,
      'version': artifact.version,
      'path': artifact.path,
      'createdAt': artifact.createdAt,
    };

    try {
      final result = await _db.query(sql, params);
      final id = result.first[0] as int;
      _log.info('Artifact salvo no banco: id=$id, version=${artifact.version}');
      return artifact.copyWith(id: id);
    } catch (e, stackTrace) {
      _log.severe('Erro ao salvar artifact', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<ArtifactEntity?> getByPath(String namespace, String path) async {
    _log.fine('Buscando artifact: namespace=$namespace, path=$path');
    try {
      final res = await _db.query(
        '''
          SELECT a.*, b.hash as blob_hash, b.size_bytes, b.mime_type 
          FROM artifacts a
          JOIN packages p ON a.package_id = p.id
          JOIN repositories r ON p.repository_id = r.id
          JOIN blobs b ON a.blob_id = b.id
          WHERE r.namespace = @namespace AND a.path = @path
          LIMIT 1
        ''',
        {'namespace': namespace, 'path': path},
      );

      if (res.isEmpty) {
        _log.fine('Artifact não encontrado para o path especificado');
        return null;
      }
      _log.fine('Artifact encontrado no banco');
      return ArtifactEntity.fromRepository(
        res.first.toColumnMap(),
        res.first.toColumnMap(),
      );
    } catch (e, stackTrace) {
      _log.severe('Erro ao buscar artifact por path', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ArtifactEntity>> listArtifactsByPackage(int packageId) async {
    _log.fine('Listando versões do package ID: $packageId');
    try {
      final res = await _db.query(
        '''
          SELECT a.*, b.hash as blob_hash, b.size_bytes, b.mime_type 
          FROM artifacts a
          JOIN blobs b ON a.blob_id = b.id
          WHERE a.package_id = @pkgId
          ORDER BY a.created_at DESC
        ''',
        {'pkgId': packageId},
      );

      _log.info('${res.length} versões encontradas para package $packageId');
      return res
          .map(
            (row) => ArtifactEntity.fromRepository(
              row.toColumnMap(),
              row.toColumnMap(),
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      _log.severe('Erro ao listar artifacts por package', e, stackTrace);
      return [];
    }
  }

  @override
  Future<ArtifactEntity?> getByExternalId(String externalId) async {
    final res = await _db.query(
      '''
        SELECT a.*, b.hash as blob_hash, b.size_bytes, b.mime_type 
        FROM artifacts a 
        JOIN blobs b ON a.blob_id = b.id 
        WHERE a.external_id = @extId
      ''',
      {'extId': externalId},
    );
    if (res.isEmpty) return null;
    return ArtifactEntity.fromRepository(
      res.first.toColumnMap(),
      res.first.toColumnMap(),
    );
  }

  @override
  Future<List<ArtifactEntity>> listByNamespace(String namespace) async {
    final res = await _db.query(
      '''
        SELECT a.*, b.hash as blob_hash, b.size_bytes, b.mime_type 
        FROM artifacts a
        JOIN packages p ON a.package_id = p.id
        JOIN repositories r ON p.repository_id = r.id
        JOIN blobs b ON a.blob_id = b.id
        WHERE r.namespace = @namespace
      ''',
      {'namespace': namespace},
    );
    return res
        .map(
          (row) => ArtifactEntity.fromRepository(
            row.toColumnMap(),
            row.toColumnMap(),
          ),
        )
        .toList();
  }

  @override
  Future<String?> findHashByVersion(
    String namespace,
    String name,
    String version,
  ) async {
    try {
      _log.info('🔍 Buscando hash no banco: $namespace/$name@$version');

      final result = await _db.query(
        '''
      SELECT b.hash 
        FROM artifacts a
        JOIN packages p ON a.package_id = p.id
        JOIN repositories r ON p.repository_id = r.id
        JOIN blobs b ON a.blob_id = b.id
      WHERE r.namespace = @namespace 
        AND p.name = @repo_name 
        AND a.version = @version
      LIMIT 1
    ''',
        {'namespace': namespace, 'repo_name': name, 'version': version},
      );

      if (result.isEmpty) {
        _log.warning('⚠️ Nenhum hash encontrado para $name@$version');
        return null;
      }

      final hash = result.first[0] as String;
      _log.info('✅ Hash localizado: ${hash.substring(0, 12)}...');

      return hash;
    } catch (e, stack) {
      _log.severe('🔥 Erro ao buscar hash por versão no Postgres', e, stack);
      rethrow;
    }
  }

  @override
  Future<ArtifactEntity?> findOne(
    String repoName,
    String packageName,
    String version,
  ) async {
    final result = await _db.query(
      '''
    SELECT a.*, r.name as repo_name, r.namespace as repo_namespace
    FROM artifacts a
    JOIN packages p ON a.package_id = p.id
    JOIN repositories r ON p.repository_id = r.id
    WHERE r.name = @repoName 
      AND p.name = @packageName 
      AND a.version = @version
    LIMIT 1
    ''',
      {'repoName': repoName, 'packageName': packageName, 'version': version},
    );

    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();
    return ArtifactEntity.fromMap(row);
  }

  @override
  Future<void> delete(ArtifactEntity artifact) async {
    if (artifact.id == null) return;
    _log.info('Deletando artifact ID: ${artifact.id}');
    await _db.execute('DELETE FROM artifacts WHERE id = @id', {
      'id': artifact.id.toString(),
    });
  }
}
