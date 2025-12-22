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
    _log.fine(
      'Salvando Blob: hash=${blob.hashValue.substring(0, 10)}..., size=${blob.sizeBytes} bytes',
    );

    try {
      const sql = '''
        INSERT INTO blobs (hash, size_bytes, mime_type)
        VALUES (@hash, @size, @mime)
        ON CONFLICT (hash) DO UPDATE SET hash = EXCLUDED.hash
        RETURNING id, hash, size_bytes, mime_type;
      ''';

      final result = await _db.query(sql, {
        'hash': blob.hashValue,
        'size': blob.sizeBytes,
        'mime': blob.mimeType,
      });

      if (result.isEmpty) {
        throw Exception(
          "Falha ao salvar Blob: Nenhuma linha retornada pelo banco.",
        );
      }

      final row = result.first.toColumnMap();
      _log.info(
        'Blob salvo no banco! ID: ${row['id']}, hash=${blob.hashValue.substring(0, 12)}...',
      );

      return BlobEntity.restore(
        row['id'] as int,
        row['hash'] as String,
        row['size_bytes'] as int,
        row['mime_type'] as String,
        row['created_at'] != null
            ? (row['created_at'] as DateTime)
            : DateTime.now(),
      );
    } catch (e, stackTrace) {
      _log.severe('Erro ao salvar blob: ${blob.hashValue}', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<BlobEntity?> findByHash(String hashValue) async {
    try {
      final result = await _db.query('SELECT * FROM blobs WHERE hash = @hash', {
        'hash': hashValue,
      });

      if (result.isEmpty) {
        _log.fine('Hash não encontrado: ${hashValue.substring(0, 10)}...');
        return null;
      }

      final row = result.first.toColumnMap();
      return BlobEntity.restore(
        row['id'] as int,
        row['hash'] as String,
        row['size_bytes'] as int,
        row['mime_type'] as String,
        row['created_at'] != null
            ? (row['created_at'] as DateTime)
            : DateTime.now(),
      );
    } catch (e, stackTrace) {
      _log.severe('Erro ao buscar blob por hash', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> exists(String hashValue) async {
    try {
      final result = await _db.query(
        'SELECT 1 FROM blobs WHERE hash = @hash LIMIT 1',
        {'hash': hashValue},
      );
      final exists = result.isNotEmpty;
      _log.fine('Check exists: ${hashValue.substring(0, 10)}... -> $exists');
      return exists;
    } catch (e, stackTrace) {
      _log.severe('Erro no check exists', e, stackTrace);
      return false;
    }
  }

  @override
  Future<void> delete(int id) async {
    _log.info('Deletando blob ID: $id');
    try {
      await _db.query('DELETE FROM blobs WHERE id = @id', {'id': id});
    } catch (e, stackTrace) {
      _log.severe('Erro ao deletar blob $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<BlobEntity?> findById(int id) async {
    final result = await _db.query('SELECT * FROM blobs WHERE id = @id', {
      'id': id,
    });
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    return BlobEntity.restore(
      row['id'] as int,
      row['hash'] as String,
      row['size_bytes'] as int,
      row['mime_type'] as String,
      row['created_at'] != null
          ? (row['created_at'] as DateTime)
          : DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
