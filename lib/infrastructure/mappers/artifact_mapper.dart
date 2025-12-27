import 'package:sambura_core/domain/entities/entities.dart';

class ArtifactMapper {
  static ArtifactEntity fromMap(Map<String, dynamic> map) {
    return ArtifactEntity.restore(
      id: map['id'] as int?,
      externalId: (map['external_id'] ?? '') as String,
      packageId: map['package_id'] as int,
      namespace: (map['namespace'] ?? '') as String,
      packageName: (map['package_name'] ?? '') as String,
      version: (map['version'] ?? '0.0.0') as String,
      path: (map['path'] ?? '') as String,
      blobId: map['blob_id'] as int?,
      blob: map['blob_hash'] != null
          ? BlobEntity.restore(
              id: map['blob_id'],
              hash: map['blob_hash'],
              size: map['blob_size'],
              mime: map['blob_mime'],
              createdAt: null,
            )
          : null,
      createdAt: map['created_at'] is DateTime
          ? (map['created_at'] as DateTime).toUtc()
          : DateTime.parse(map['created_at'].toString()).toUtc(),
    );
  }
}
