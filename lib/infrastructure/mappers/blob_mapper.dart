import 'package:sambura_core/domain/entities/blob_entity.dart';

class BlobMapper {
  static BlobEntity fromMap(Map<String, dynamic> map) {
    return BlobEntity.restore(
      id: map['id'] as int?,
      hash: map['hash'] as String,
      size: map['size_bytes'] as int,
      mime: map['mime_type'] as String,
      createdAt: map['created_at'] != null
          ? (map['created_at'] as DateTime).toUtc()
          : null,
    );
  }

  static Map<String, dynamic> toMap(BlobEntity blob) {
    return {
      'id': blob.id,
      'hash': blob.hash,
      'size_bytes': blob.sizeBytes,
      'mime_type': blob.mimeType,
      'created_at': blob.createdAt?.toIso8601String(),
    };
  }
}
