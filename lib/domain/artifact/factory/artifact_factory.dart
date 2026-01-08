import 'package:sambura_core/domain/entities/entities.dart';

class ArtifactFactory {
  static ArtifactEntity create({
    required int packageId,
    required String namespace,
    required String packageName,
    required String version,
    required BlobEntity blob,
    required String path,
  }) {
    return ArtifactEntity.create(
      packageId: packageId,
      namespace: namespace,
      packageName: packageName,
      version: version,
      blob: blob,
      path: path,
    );
  }
}
