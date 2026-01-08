import 'dart:typed_data';
import 'package:sambura_core/domain/artifact/artifact.dart';

class InMemoryBlobRepository implements BlobRepository {
  // Simula a tabela de metadados
  final Map<int, BlobEntity> _blobsById = {};
  final Map<String, BlobEntity> _blobsByHash = {};

  // Simula o storage físico (S3/MinIO)
  final Map<String, Uint8List> _physicalStorage = {};

  bool shouldThrowError = false;

  void _checkError() {
    if (shouldThrowError) throw Exception('Storage/Database error');
  }

  @override
  Future<BlobEntity> save(BlobEntity blob) async {
    _checkError();
    _blobsById[blob.id!] = blob;
    _blobsByHash[blob.hash] = blob;
    return blob;
  }

  @override
  Future<BlobEntity> saveContent(String hash, Uint8List bytes) async {
    _checkError();
    _physicalStorage[hash] = bytes;

    final entity =
        _blobsByHash[hash] ??
        BlobEntity.create(hash: hash, size: bytes.length, mime: "");

    return save(entity);
  }

  @override
  Future<BlobEntity> saveFromStream(Stream<List<int>> byteStream) async {
    _checkError();
    final List<int> allBytes = [];
    await for (final chunk in byteStream) {
      allBytes.addAll(chunk);
    }

    final bytes = Uint8List.fromList(allBytes);
    final hash = 'mock_hash_${DateTime.now().millisecondsSinceEpoch}';

    return saveContent(hash, bytes);
  }

  @override
  Future<BlobEntity?> findByHash(String hash) async {
    _checkError();
    return _blobsByHash[hash];
  }

  @override
  Future<BlobEntity?> findById(int id) async {
    _checkError();
    return _blobsById[id];
  }

  @override
  Future<bool> exists(String hash) async {
    _checkError();
    return _physicalStorage.containsKey(hash);
  }

  @override
  Future<Stream<Uint8List>> readAsStream(String hash) async {
    _checkError();
    final content = _physicalStorage[hash];
    if (content == null) throw Exception('Blob not found in physical storage');

    return Stream.value(content);
  }

  @override
  Future<void> delete(int id) async {
    _checkError();
    final blob = _blobsById[id];
    if (blob != null) {
      _blobsByHash.remove(blob.hash);
      _physicalStorage.remove(blob.hash);
      _blobsById.remove(id);
    }
  }

  void clear() {
    _blobsById.clear();
    _blobsByHash.clear();
    _physicalStorage.clear();
  }
}
