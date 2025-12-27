import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';
import 'package:sambura_core/infrastructure/mappers/artifact_mapper.dart';
import 'package:sambura_core/infrastructure/mappers/blob_mapper.dart';
import 'package:sambura_core/domain/entities/entities.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';

class PostgresArtifactRepository implements ArtifactRepository {
  final PostgresConnector _connection;
  final Logger _log = LoggerConfig.getLogger('PostgresArtifactRepository');

  PostgresArtifactRepository(this._connection);

  @override
  Future<ArtifactEntity> save(ArtifactEntity artifact) async {
    // Usamos um DO UPDATE SET version = EXCLUDED.version (que não muda nada)
    // apenas para forçar o RETURNING a devolver a linha em caso de conflito.
    const sql = '''
    INSERT INTO artifacts (package_id, blob_id, external_id, version, path, created_at)
    VALUES (@packageId, @blobId, @externalId, @version, @path, @createdAt)
    ON CONFLICT ON CONSTRAINT unique_version_per_package 
    DO UPDATE SET version = EXCLUDED.version
    RETURNING id;
  ''';

    try {
      final result = await _connection.query(
        sql,
        substitutionValues: {
          'packageId': artifact.packageId,
          'blobId': artifact.blob!.id,
          'externalId': artifact.externalId.value,
          'version': artifact.version.value,
          'path': artifact.path,
          'createdAt': artifact.createdAt,
        },
      );

      final id = result.first[0] as int;

      _log.info(
        '📦 Artifact processado (Insert/Upsert): id=$id, version=${artifact.version}',
      );
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
      final res = await _connection.query(
        '''
          SELECT a.*, b.hash as blob_hash, b.size_bytes, b.mime_type 
          FROM artifacts a
          JOIN packages p ON a.package_id = p.id
          JOIN repositories r ON p.repository_id = r.id
          JOIN blobs b ON a.blob_id = b.id
          WHERE r.namespace = @namespace AND a.path = @path
          LIMIT 1
        ''',
        substitutionValues: {'namespace': namespace, 'path': path},
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
      final res = await _connection.query(
        '''
          SELECT a.*, b.hash as blob_hash, b.size_bytes, b.mime_type 
          FROM artifacts a
          JOIN blobs b ON a.blob_id = b.id
          WHERE a.package_id = @pkgId
          ORDER BY a.created_at DESC
        ''',
        substitutionValues: {'pkgId': packageId},
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
    final res = await _connection.query(
      '''
        SELECT a.*, b.hash as blob_hash, b.size_bytes, b.mime_type 
        FROM artifacts a 
        JOIN blobs b ON a.blob_id = b.id 
        WHERE a.external_id = @extId
      ''',
      substitutionValues: {'extId': externalId},
    );
    if (res.isEmpty) return null;
    return _fromRepository(res.first.toColumnMap(), res.first.toColumnMap());
  }

  @override
  Future<List<ArtifactEntity>> listByNamespace(String namespace) async {
    final res = await _connection.query(
      '''
        SELECT a.*, b.hash as blob_hash, b.size_bytes, b.mime_type 
        FROM artifacts a
        JOIN packages p ON a.package_id = p.id
        JOIN repositories r ON p.repository_id = r.id
        JOIN blobs b ON a.blob_id = b.id
        WHERE r.namespace = @namespace
      ''',
      substitutionValues: {'namespace': namespace},
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

      final result = await _connection.query(
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
        substitutionValues: {
          'repo_name': namespace,
          'package_name': name,
          'version': version,
        },
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
  Future<ArtifactEntity?> findByNameAndVersion(
    String namespace,
    String name,
    String version,
  ) async {
    return await _connection
        .query(
          '''
    SELECT id, external_id, namespace, name, version, metadata, created_at
    FROM artifacts
    WHERE namespace = @namespace 
      AND name = @name 
      AND version = @version
    LIMIT 1
    ''',
          substitutionValues: {
            'namespace': namespace,
            'name': name,
            'version': version,
          },
        )
        .then((result) {
          if (result.isEmpty) return null;

          // Mapeia o primeiro (e único) resultado para sua Entity
          return ArtifactMapper.fromMap(result.first.toColumnMap());
        });
  }

  @override
  Future<ArtifactEntity?> findByFileName(
    String repositoryName,
    String packageName,
    String fileName,
  ) async {
    final query = '''
      SELECT 
          a.*, 
          r.name as namespace, 
          p.name as package_name,
          b.hash as blob_hash,
          b.size_bytes as blob_size,
          b.mime_type as blob_mime
      FROM artifacts a
      INNER JOIN packages p ON a.package_id = p.id
      INNER JOIN repositories r ON p.repository_id = r.id
      LEFT JOIN blobs b ON a.blob_id = b.id -- JOIN necessário para preencher o objeto blob
      WHERE a.path = @file AND p.name = @pkg AND r.name = @repo
      LIMIT 1;
    ''';

    final result = await _connection.query(
      query,
      substitutionValues: {
        'repo': repositoryName,
        'pkg': packageName,
        'file': fileName,
      },
    );

    if (result.isEmpty) return null;

    return ArtifactMapper.fromMap(result.first.toColumnMap());
  }

  @override
  Future<ArtifactEntity?> findOne(
    String repoName,
    String packageName,
    String version,
  ) async {
    final result = await _connection.query(
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
      substitutionValues: {
        'repoName': repoName,
        'packageName': packageName,
        'version': version,
      },
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
    final results = await _connection.query(
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
      substitutionValues: {'packageName': packageName, 'repoName': repoName},
    );

    return results.map((row) {
      final map = row.toColumnMap();

      final artifact = _fromMap({
        'id': map['id'],
        'external_id': map['external_id'].toString(),
        'package_id': map['package_id'],
        'repo_namespace': (map['repo_name'] ?? '').toString(),
        'namespace': (map['repo_name'] ?? '').toString(),
        'package_name': (map['pkg_name'] ?? '').toString(),
        'version': map['version'].toString(),
        'path': (map['path'] ?? '').toString(),
        'blob_id': map['blob_id'],
        'created_at': (map['created_at'] ?? DateTime.now()).toString(),
        'blob_data': {
          'id': map['b_id'],
          'hash': (map['b_hash'] ?? '').toString(),
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
    await _connection.execute('DELETE FROM artifacts WHERE id = @id', {
      'id': artifact.id.toString(),
    });
  }

  ArtifactEntity _fromMap(Map<String, dynamic> map, {BlobEntity? blob}) {
    return ArtifactEntity.restore(
      id: map['id'] as int,
      externalId: map['external_id'].toString(),
      packageId: map['package_id'] as int,
      namespace: map['namespace'] as String? ?? '',
      packageName: (map['package_name'] ?? map['name']) as String,
      version: map['version'].toString(),
      path: map['path'] as String,
      blobId: map['blob_id'] as int?,
      blob:
          blob ??
          (map['blob_data'] != null
              ? BlobMapper.fromMap(map['blob_data'])
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
      externalId: artifactRow['external_id'].toString(),
      packageId: artifactRow['package_id'] as int,
      namespace: artifactRow['namespace'] as String? ?? '',
      packageName:
          (artifactRow['package_name'] ?? artifactRow['name']) as String,
      version: artifactRow['version'] as String,
      path: artifactRow['path'] as String,
      blobId: artifactRow['blob_id'] as int?,
      // Reconstrói o BlobEntity usando o restore dele
      blob: BlobMapper.fromMap(blobRow),
      createdAt: artifactRow['created_at'] is DateTime
          ? artifactRow['created_at'] as DateTime
          : DateTime.parse(artifactRow['created_at'].toString()),
    );
  }

  @override
  Future<bool> isHealthy() async {
    try {
      // Executa uma query mínima para testar a conexão
      final result = await _connection.query('SELECT 1');
      return result.isNotEmpty;
    } catch (e) {
      _log.severe('❌ Database health check falhou: $e');
      return false;
    }
  }
}
