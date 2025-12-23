import 'package:sambura_core/domain/entities/artifact_entity.dart';
import 'package:sambura_core/domain/entities/blob_entity.dart';
import 'package:sambura_core/domain/value_objects/package_name.dart';
import 'package:sambura_core/domain/value_objects/version.dart';

/// Factory para criação de ArtifactEntity.
/// 
/// Aplica o padrão Factory para encapsular a lógica complexa
/// de criação de artefatos, garantindo que todas as regras de negócio
/// sejam aplicadas corretamente.
class ArtifactFactory {
  /// Cria um novo artefato a partir de dados brutos.
  /// 
  /// Valida e encapsula a criação usando Value Objects.
  static ArtifactEntity create({
    required int packageId,
    required String repositoryName,
    required String packageName,
    required String version,
    required String path,
    required BlobEntity blob,
  }) {
    // Validação através de Value Objects
    final validatedPackageName = PackageName.create(packageName);
    final validatedVersion = Version.create(version);

    // Cria a entidade com todos os dados validados
    return ArtifactEntity.create(
      packageId: packageId,
      namespace: repositoryName,
      packageName: validatedPackageName.value,
      version: validatedVersion.value,
      path: path,
      blob: blob,
    );
  }

  /// Reconstrói um artefato a partir dos dados do banco.
  /// 
  /// Usado pelos repositórios ao recuperar dados do banco.
  /// Não aplica validações rigorosas pois assume dados já validados.
  static ArtifactEntity fromDatabase(
    Map<String, dynamic> artifactRow,
    Map<String, dynamic> blobRow,
  ) {
    return ArtifactEntity.fromRepository(artifactRow, blobRow);
  }

  /// Cria um artefato para testes.
  /// 
  /// Útil em ambientes de teste e desenvolvimento.
  static ArtifactEntity createForTest({
    int? id,
    required String packageName,
    required String version,
    String repositoryName = 'test-repo',
    String? blobHash,
  }) {
    final validatedPackageName = PackageName.unsafe(packageName);
    final validatedVersion = Version.unsafe(version);

    final blob = BlobEntity.create(
      hash: blobHash ?? 'a' * 64,
      size: 1024,
      mime: 'application/octet-stream',
    );

    return ArtifactEntity.create(
      packageId: 1,
      namespace: repositoryName,
      packageName: validatedPackageName.value,
      version: validatedVersion.value,
      path: '/$packageName-$version.tgz',
      blob: blob,
    );
  }
}
