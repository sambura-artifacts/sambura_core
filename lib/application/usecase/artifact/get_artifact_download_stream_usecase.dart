import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/entities/blob_entity.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';
import 'package:sambura_core/domain/repositories/blob_repository.dart';
import 'package:sambura_core/infrastructure/services/cache/redis_service.dart';

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
    _log.info('Iniciando download: $namespace/$name@$version');

    try {
      final cacheKey = 'hash:$namespace:$name:$version';

      _log.fine('Verificando cache Redis: $cacheKey');
      final cachedHash = await _redis.get(cacheKey);

      if (cachedHash != null) {
        _log.info(
          '✓ Cache Hit! Hash do Redis: ${cachedHash.substring(0, 12)}... para $name@$version',
        );
        return _fetchFromSilo(cachedHash);
      }

      _log.fine('Cache Miss, consultando banco de dados');
      final hash = await _artifactRepo.findHashByVersion(
        namespace,
        name,
        version,
      );

      if (hash == null) {
        _log.warning('✗ Hash não encontrado para $namespace/$name@$version');
        return null;
      }

      _log.fine(
        'Hash encontrado: ${hash.substring(0, 12)}..., atualizando cache',
      );
      await _redis.set(cacheKey, hash, expirySeconds: 86400);
      _log.fine('Cache atualizado com TTL de 24h');

      return _fetchFromSilo(hash);
    } catch (e, stack) {
      _log.severe(
        '✗ Erro durante download de $namespace/$name@$version',
        e,
        stack,
      );
      rethrow;
    }
  }

  Future<ArtifactDownloadResult?> _fetchFromSilo(String hash) async {
    _log.fine('Buscando blob no silo: ${hash.substring(0, 12)}...');

    try {
      final blob = await _blobRepo.findByHash(hash);
      if (blob == null) {
        _log.severe(
          '✗ INCONSISTÊNCIA: Hash $hash existe no banco/cache, mas blob não encontrado no storage!',
        );
        return null;
      }

      _log.fine(
        'Blob encontrado: ${blob.sizeBytes} bytes, mime: ${blob.mimeType}',
      );
      _log.fine('Abrindo stream de leitura');
      final stream = await _blobRepo.readAsStream(hash);

      _log.info('✓ Stream de download iniciado: ${blob.sizeBytes} bytes');
      return ArtifactDownloadResult(stream, blob);
    } catch (e, stack) {
      _log.severe(
        '✗ Erro ao buscar blob do silo: ${hash.substring(0, 12)}...',
        e,
        stack,
      );
      rethrow;
    }
  }
}
