import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/blob_repository.dart';
import 'package:sambura_core/domain/entities/blob_entity.dart';
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';

class PostgresBlobRepository implements BlobRepository {
  final PostgresConnector _db;
  final Logger _log = LoggerConfig.getLogger('PostgresBlobRepository');

  PostgresBlobRepository(this._db);

  @override
  Future<BlobEntity> save(BlobEntity blob) async {
    try {
      // Ajuste: Adicionado created_at no RETURNING
      const sql = '''
        INSERT INTO blobs (hash, size_bytes, mime_type)
        VALUES (@hash, @size, @mime)
        ON CONFLICT (hash) DO UPDATE SET hash = EXCLUDED.hash
        RETURNING id, hash, size_bytes, mime_type, created_at;
      ''';

      final result = await _db.query(sql, {
        'hash': blob.hashValue,
        'size': blob.sizeBytes,
        'mime': blob.mimeType,
      });

      final row = result.first.toColumnMap();
      return _mapRow(row);
    } catch (e, stackTrace) {
      _log.severe('Erro ao salvar blob', e, stackTrace);
      rethrow;
    }
  }

  // --- MÉTODOS QUE FALTAVAM PARA COMPILAR ---

  @override
  Future<BlobEntity> saveFromStream(Stream<List<int>> byteStream) async {
    // Esse método geralmente é implementado no SiloBlobRepository
    // Se precisar aqui, teria que ler a stream toda pra buffer.
    throw UnimplementedError(
      'Use o SiloBlobRepository para salvar streams, cria!',
    );
  }

  @override
  Future<Stream<Uint8List>> readAsStream(String hashValue) async {
    // A leitura do binário é papel do Storage (MinIO)
    throw UnimplementedError(
      'O binário mora no MinIO, busque via SiloBlobRepository!',
    );
  }

  // --- BUSCAS ---

  @override
  Future<BlobEntity?> findByHash(String hashValue) async {
    final result = await _db.query('SELECT * FROM blobs WHERE hash = @hash', {
      'hash': hashValue,
    });
    return result.isEmpty ? null : _mapRow(result.first.toColumnMap());
  }

  @override
  Future<BlobEntity?> findById(int id) async {
    final result = await _db.query('SELECT * FROM blobs WHERE id = @id', {
      'id': id,
    });
    return result.isEmpty ? null : _mapRow(result.first.toColumnMap());
  }

  @override
  Future<bool> exists(String hashValue) async {
    final result = await _db.query('SELECT 1 FROM blobs WHERE hash = @hash', {
      'hash': hashValue,
    });
    return result.isNotEmpty;
  }

  @override
  Future<void> delete(int id) async {
    await _db.query('DELETE FROM blobs WHERE id = @id', {'id': id});
  }

  // Helper pra não repetir código de mapeamento
  BlobEntity _mapRow(Map<String, dynamic> row) {
    return BlobEntity.restore(
      row['id'] as int,
      row['hash'] as String,
      row['size_bytes'] as int,
      row['mime_type'] as String,
      row['created_at'] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  Future<BlobEntity> saveContent(String hash, Uint8List bytes) {
    throw UnimplementedError();
  }
}
