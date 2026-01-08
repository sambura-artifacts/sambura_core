import 'dart:typed_data';
import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/artifact/ports/ports.dart';
import 'package:sambura_core/domain/entities/entities.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';

class StorageBlobRepository implements BlobRepository {
  final StoragePort _storagePort;
  final BlobRepository _dbRepository;
  final Logger _log = LoggerConfig.getLogger('SiloBlobRepository');

  StorageBlobRepository(this._storagePort, this._dbRepository);

  @override
  Future<BlobEntity> saveFromStream(Stream<List<int>> byteStream) async {
    final splitter = StreamSplitter(byteStream);
    final metadataStream = splitter.split();
    final storageStream = splitter.split().cast<Uint8List>();
    splitter.close();

    final blobMetadata = await BlobEntity.fromStream(metadataStream);

    final blobWithId = await _dbRepository.save(blobMetadata);

    try {
      final exists = await _storagePort.exists(blobWithId.hash);

      if (exists) {
        _log.info(
          '📦 Blob duplicado (já no storage): ${blobWithId.hash.substring(0, 12)}',
        );
        return blobWithId;
      }

      await _storagePort.store(
        path: blobWithId.hash,
        stream: storageStream,
        sizeBytes: blobWithId.sizeBytes,
      );

      _log.info('✅ Blob armazenado: ${blobWithId.hash.substring(0, 12)}');
    } catch (e) {
      _log.severe('❌ Erro ao persistir binário: $e');
      rethrow;
    }

    return blobWithId;
  }

  @override
  Future<Stream<Uint8List>> readAsStream(String hash) async {
    final stream = await _storagePort.retrieve(hash);
    return stream.map((chunk) => Uint8List.fromList(chunk));
  }

  @override
  Future<BlobEntity?> findByHash(String hash) async {
    return await _dbRepository.findByHash(hash);
  }

  @override
  Future<BlobEntity> saveContent(String hash, Uint8List bytes) async {
    final existing = await _dbRepository.findByHash(hash);
    if (existing != null) return existing;

    final entity = BlobEntity.create(
      hash: hash,
      size: bytes.length,
      mime: 'application/octet-stream',
    );

    final saved = await _dbRepository.save(entity);

    await _storagePort.store(
      path: saved.hash,
      stream: Stream.value(bytes),
      sizeBytes: saved.sizeBytes,
    );

    return saved;
  }

  @override
  Future<bool> exists(String hash) async {
    final blob = await _dbRepository.findByHash(hash);
    if (blob == null) return false;

    return await _storagePort.exists(hash);
  }

  @override
  Future<BlobEntity?> findById(int id) async {
    return await _dbRepository.findById(id);
  }

  @override
  Future<BlobEntity> save(BlobEntity entity) async {
    return await _dbRepository.save(entity);
  }

  @override
  Future<void> delete(int id) async {
    try {
      final blob = await _dbRepository.findById(id);

      if (blob == null) return;

      await _storagePort.delete(blob.hash);

      _log.info('🗑️ Blob deletado: ${blob.hash.substring(0, 12)}');
    } catch (e) {
      _log.severe('❌ Falha ao deletar blob: $e');
      rethrow;
    }
  }
}
