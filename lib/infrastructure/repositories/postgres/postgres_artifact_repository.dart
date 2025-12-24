import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/entities/blob_entity.dart';
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
      return _fromRepository(res.first.toColumnMap(), res.first.toColumnMap());
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
          .map((row) => _fromRepository(row.toColumnMap(), row.toColumnMap()))
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
    return _fromRepository(res.first.toColumnMap(), res.first.toColumnMap());
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
        .map((row) => _fromRepository(row.toColumnMap(), row.toColumnMap()))
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
      WHERE r.name = @repo_name 
        AND p.name = @package_name 
        AND a.version = @version
      LIMIT 1
    ''',
        {'repo_name': namespace, 'package_name': name, 'version': version},
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
    return _fromMap(row);
  }

  @override
  Future<List<ArtifactEntity>> findAllVersions(
    String repoName,
    String packageName,
  ) async {
    final results = await _db.query(
      '''
    SELECT 
      a.id, a.external_id, a.version, a.path, a.created_at, a.package_id, a.blob_id,
      r.name as repo_name, 
      p.name as pkg_name,
      b.id as b_id, b.hash as b_hash, b.size_bytes as b_size_bytes, b.mime_type as b_mime_type, b.created_at as b_at
    FROM artifacts a
    JOIN packages p ON a.package_id = p.id
    JOIN repositories r ON p.repository_id = r.id
    JOIN blobs b ON a.blob_id = b.id
    WHERE p.name = @packageName AND r.name = @repoName
  ''',
      {'packageName': packageName, 'repoName': repoName},
    );

    return results.map((row) {
      final map = row.toColumnMap();

      final artifact = _fromMap({
        'id': map['id'],
        'external_id': '${map['external_id'] ?? ''}',
        'package_id': map['package_id'],
        'repo_namespace': (map['repo_name'] ?? '').toString(),
        'namespace': (map['repo_name'] ?? '').toString(),
        'package_name': (map['pkg_name'] ?? '').toString(),
        'version': (map['version'] ?? '').toString(),
        'path': (map['path'] ?? '').toString(),
        'blob_id': map['blob_id'],
        'created_at': (map['created_at'] ?? DateTime.now()).toString(),
        'blob_data': {
          'id': map['b_id'],
          'hash_value': (map['b_hash'] ?? '').toString(),
          'size_bytes': map['b_size_bytes'] ?? 0,
          'mime_type': (map['b_mime_type'] ?? 'application/octet-stream')
              .toString(),
          'created_at': (map['b_at'] ?? DateTime.now()).toString(),
        },
      });
      return artifact;
    }).toList();
  }

  @override
  Future<void> delete(ArtifactEntity artifact) async {
    if (artifact.id == null) return;
    _log.info('Deletando artifact ID: ${artifact.id}');
    await _db.execute('DELETE FROM artifacts WHERE id = @id', {
      'id': artifact.id.toString(),
    });
  }

  ArtifactEntity _fromMap(Map<String, dynamic> map, {BlobEntity? blob}) {
    return ArtifactEntity.restore(
      id: map['id'] as int,
      externalId: map['external_id'] as String,
      packageId: map['package_id'] as int,
      namespace: map['namespace'] as String? ?? '',
      packageName: (map['package_name'] ?? map['name']) as String,
      version: map['version'] as String,
      path: map['path'] as String,
      blobId: map['blob_id'] as int?,
      blob:
          blob ??
          (map['blob_data'] != null
              ? BlobEntity.fromMap(map['blob_data'])
              : null),
      createdAt: map['created_at'] is DateTime
          ? map['created_at'] as DateTime
          : DateTime.parse(map['created_at'].toString()),
    );
  }

  ArtifactEntity _fromRepository(
    Map<String, dynamic> artifactRow,
    Map<String, dynamic> blobRow,
  ) {
    return ArtifactEntity.restore(
      id: artifactRow['id'] as int,
      externalId: artifactRow['external_id'] as String,
      packageId: artifactRow['package_id'] as int,
      namespace: artifactRow['namespace'] as String? ?? '',
      packageName:
          (artifactRow['package_name'] ?? artifactRow['name']) as String,
      version: artifactRow['version'] as String,
      path: artifactRow['path'] as String,
      blobId: artifactRow['blob_id'] as int?,
      // Reconstrói o BlobEntity usando o restore dele
      blob: BlobEntity.restore(
        blobRow['id'] as int,
        blobRow['hash_value'] as String,
        blobRow['size_bytes'] as int,
        blobRow['mime_type'] as String,
        blobRow['created_at'] is DateTime
            ? blobRow['created_at'] as DateTime
            : DateTime.parse(blobRow['created_at'].toString()),
      ),
      createdAt: artifactRow['created_at'] is DateTime
          ? artifactRow['created_at'] as DateTime
          : DateTime.parse(artifactRow['created_at'].toString()),
    );
  }
}
