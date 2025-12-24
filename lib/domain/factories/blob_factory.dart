import 'package:sambura_core/domain/entities/blob_entity.dart';

/// Factory para criar instâncias de BlobEntity
class BlobFactory {
  /// Cria um novo blob a partir de hash, tamanho e mime type
  static BlobEntity create({
    required String hash,
    required int size,
    required String mime,
  }) {
    return BlobEntity.create(hash: hash, size: size, mime: mime);
  }

  /// Cria um blob a partir de um stream
  static Future<BlobEntity> fromStream(Stream<List<int>> stream) async {
    return await BlobEntity.fromStream(stream);
  }
}
