import 'dart:typed_data';
import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/shared/ports/ports.dart';
import 'package:sambura_core/domain/entities/entities.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';

class SiloBlobRepository implements BlobRepository {
  final StoragePort _storagePort;
  final BlobRepository _dbRepository; // Repositório Postgres
  final Logger _log = LoggerConfig.getLogger('SiloBlobRepository');

  SiloBlobRepository(this._storagePort, this._dbRepository);

  @override
  Future<BlobEntity> saveFromStream(Stream<List<int>> byteStream) async {
    final splitter = StreamSplitter(byteStream);
    final metadataStream = splitter.split();
    final storageStream = splitter.split().cast<Uint8List>();
    splitter.close();

    // Calcula hash e tamanho sem carregar tudo em memória
    final blobMetadata = await BlobEntity.fromStream(metadataStream);

    // 1. Salva metadados no Postgres
    final blobWithId = await _dbRepository.save(blobMetadata);

    try {
      // 2. Verifica se o binário já existe no Storage (Deduplicação)
      final exists = await _storagePort.exists(blobWithId.hash);

      if (exists) {
        _log.info(
          '📦 Blob duplicado (já no storage): ${blobWithId.hash.substring(0, 12)}',
        );
        return blobWithId;
      }

      // 3. Salva o binário real
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
    // StoragePort.retrieve retorna Stream<List<int>>
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

  // ... dentro da classe SiloBlobRepository

  @override
  Future<bool> exists(String hash) async {
    // Primeiro checa no banco, pois é mais rápido que IO de rede no S3
    final blob = await _dbRepository.findByHash(hash);
    if (blob == null) return false;

    // Opcional: Validar se o arquivo físico ainda existe no storage
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
