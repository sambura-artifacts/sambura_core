import 'dart:async';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:minio/minio.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/ports/storage_port.dart';

/// Adapter para MinIO/S3 implementando StoragePort.
///
/// Segue o padrão Hexagonal Architecture (Ports & Adapters).
class MinioStorageAdapter implements StoragePort {
  final Minio _client;
  final String _bucket;
  final Logger _log = LoggerConfig.getLogger('MinioAdapter');

  MinioStorageAdapter({
    required String endPoint,
    required int port,
    required String accessKey,
    required String secretKey,
    required String bucket,
    bool useSSL = false,
  }) : _client = Minio(
         endPoint: endPoint,
         port: port,
         useSSL: useSSL,
         accessKey: accessKey,
         secretKey: secretKey,
       ),
       _bucket = bucket;

  @override
  Future<void> store({
    required String path,
    required Stream<Uint8List> stream,
    required int sizeBytes,
    String contentType = 'application/octet-stream',
  }) async {
    try {
      _log.info('📤 Storing object: $_bucket/$path ($sizeBytes bytes)');

      await _client.putObject(
        _bucket,
        path,
        stream,
        size: sizeBytes,
        metadata: {'Content-Type': contentType},
      );

      _log.info('✅ Object stored successfully');
    } catch (e, stack) {
      _log.severe('❌ Failed to store object: $path', e, stack);
      throw Exception('Failed to store object in storage: $e');
    }
  }

  @override
  Future<StreamView<List<int>>> retrieve(String path) async {
    try {
      _log.fine('📥 Retrieving object: $_bucket/$path');

      final stream = await _client.getObject(_bucket, path);

      _log.fine('✅ Object stream retrieved');
      return stream;
    } catch (e, stack) {
      _log.severe('❌ Failed to retrieve object: $path', e, stack);
      throw Exception('Failed to retrieve object from storage: $e');
    }
  }

  @override
  Future<bool> exists(String path) async {
    try {
      await _client.statObject(_bucket, path);
      return true;
    } catch (e) {
      _log.fine('Object does not exist: $path');
      return false;
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      _log.info('🗑️  Deleting object: $_bucket/$path');

      await _client.removeObject(_bucket, path);

      _log.info('✅ Object deleted successfully');
    } catch (e, stack) {
      _log.warning('⚠️  Failed to delete object: $path', e, stack);
      // Não propaga exceção em delete - é idempotente
    }
  }

  @override
  Future<Map<String, dynamic>> getMetadata(String path) async {
    try {
      _log.fine('📋 Getting metadata: $_bucket/$path');

      final stat = await _client.statObject(_bucket, path);

      return {
        'size': stat.size,
        'etag': stat.etag,
        'content_type':
            stat.metaData?['content-type'] ?? 'application/octet-stream',
        'last_modified': stat.lastModified,
      };
    } catch (e, stack) {
      _log.severe('❌ Failed to get metadata: $path', e, stack);
      throw Exception('Failed to get object metadata: $e');
    }
  }

  @override
  Future<bool> isHealthy() async {
    try {
      // Tenta listar os buckets. Se o MinIO estiver fora ou
      // se as credenciais (Key/Secret) estiverem erradas, isso estoura um erro.
      await _client.listBuckets();
      return true;
    } catch (e) {
      _log.severe('❌ Storage Health Check falhou: $e');
      return false;
    }
  }
}
