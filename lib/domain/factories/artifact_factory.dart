import 'package:sambura_core/domain/barrel.dart';

/// Factory para criar instâncias de ArtifactEntity
class ArtifactFactory {
  /// Cria um novo artefato
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
