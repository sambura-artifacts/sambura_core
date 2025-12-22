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
  final BlobRepository _databaseRepository;
  final Logger _log = LoggerConfig.getLogger('SiloBlobRepository');

  SiloBlobRepository(this._minio, this._bucket, this._databaseRepository);

  @override
  Future<BlobEntity> saveFromStream(Stream<List<int>> byteStream) async {
    final splitter = StreamSplitter(byteStream);
    final metadataStream = splitter.split();
    final storageStream = splitter.split().cast<Uint8List>();
    splitter.close();

    final blobMetadata = await BlobEntity.fromStream(metadataStream);

    final blobWithId = await _databaseRepository.save(blobMetadata);

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
  Future<Stream<Uint8List>> readAsStream(String hashValue) async {
    final MinioByteStream stream = await _minio.getObject(_bucket, hashValue);
    return stream.cast<Uint8List>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
