import 'dart:typed_data';
import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:minio/minio.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/entities/blob_entity.dart';
import 'package:sambura_core/domain/repositories/blob_repository.dart';

class SiloBlobRepository implements BlobRepository {
  final Minio _minio;
  final String _bucket;
  final BlobRepository _repository;
  final Logger _log = LoggerConfig.getLogger('SiloBlobRepository');

  SiloBlobRepository(this._minio, this._bucket, this._repository);

  @override
  Future<BlobEntity> saveFromStream(Stream<List<int>> byteStream) async {
    final splitter = StreamSplitter(byteStream);
    final metadataStream = splitter.split();
    final storageStream = splitter.split().cast<Uint8List>();
    splitter.close();

    final blobMetadata = await BlobEntity.fromStream(metadataStream);

    final blobWithId = await _repository.save(blobMetadata);

    try {
      await _minio.statObject(_bucket, blobWithId.hashValue);
      _log.info(
        'Blob duplicado detectado: ${blobWithId.hashValue.substring(0, 12)}...',
      );
    } catch (e) {
      await _minio.putObject(_bucket, blobWithId.hashValue, storageStream);
      _log.info(
        'Blob salvo no MinIO: ${blobWithId.hashValue.substring(0, 12)}...',
      );
    }

    return blobWithId;
  }

  @override
  Future<Stream<Uint8List>> readAsStream(String hash) async {
    try {
      _log.info('Lendo stream do MinIO: ${hash.substring(0, 12)}...');

      // O minioClient devolve Stream<List<int>>
      final stream = await _minio.getObject(_bucket, hash);

      // Converte cada "pedaço" (chunk) do stream para Uint8List
      return stream.map((chunk) => Uint8List.fromList(chunk));
    } catch (e, stack) {
      _log.severe(
        'Erro ao ler stream do blob: ${hash.substring(0, 12)}...',
        e,
        stack,
      );
      rethrow;
    }
  }

  @override
  Future<BlobEntity?> findByHash(String hash) async {
    try {
      _log.info('Buscando metadados do blob: ${hash.substring(0, 12)}...');

      final repo = await _repository.findByHash(hash);

      if (repo == null) return null;

      return BlobEntity.restore(
        repo.id!,
        repo.hashValue,
        repo.sizeBytes,
        repo.mimeType,
        repo.createdAt!,
      );
    } catch (e) {
      _log.severe('Erro ao buscar metadados: $e');
      return null;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
