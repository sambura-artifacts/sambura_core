import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/entities/blob_entity.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';
import 'package:sambura_core/domain/repositories/blob_repository.dart';
import 'package:sambura_core/infrastructure/services/redis_service.dart';

class ArtifactDownloadResult {
  final Stream<Uint8List> stream;
  final BlobEntity blob;

  ArtifactDownloadResult(this.stream, this.blob);
}

class GetArtifactDownloadStreamUsecase {
  final ArtifactRepository _artifactRepo;
  final BlobRepository _blobRepo;
  final RedisService _redis;

  final Logger _log = LoggerConfig.getLogger(
    'GetArtifactDownloadStreamUsecase',
  );

  GetArtifactDownloadStreamUsecase(
    this._artifactRepo,
    this._blobRepo,
    this._redis,
  );

  Future<ArtifactDownloadResult?> execute({
    required String namespace,
    required String name,
    required String version,
  }) async {
    _log.info('Executando download para: $namespace/$name@$version');
    final cacheKey = 'hash:$namespace:$name:$version';

    final cachedHash = await _redis.get(cacheKey);

    if (cachedHash != null) {
      _log.info(
        '🚀 Cache Hit! Hash vindo do Redis: ${cachedHash.substring(0, 12)}...',
      );
      return _fetchFromSilo(cachedHash);
    }

    final hash = await _artifactRepo.findHashByVersion(
      namespace: namespace,
      name: name,
      version: version,
    );

    if (hash == null) {
      _log.warning('Hash não encontrado para $name@$version');
      return null;
    }

    await _redis.set(cacheKey, hash, expirySeconds: 86400);

    return _fetchFromSilo(hash);
  }

  Future<ArtifactDownloadResult?> _fetchFromSilo(String hash) async {
    final blob = await _blobRepo.findByHash(hash);
    if (blob == null) {
      _log.severe(
        '❌ Inconsistência: Hash $hash no banco/cache, mas não no MinIO!',
      );
      return null;
    }

    final stream = await _blobRepo.readAsStream(hash);
    return ArtifactDownloadResult(stream, blob);
  }
}
