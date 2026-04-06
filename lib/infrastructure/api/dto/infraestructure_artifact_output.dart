import 'package:sambura_core/domain/barrel.dart';

/// DTO de saída para informar o sucesso da criação ou detalhes do artefato.
class InfraestructureArtifactOutput {
  final String externalId;
  final String namespace;
  final String packageName;
  final String version;
  final String path;

  InfraestructureArtifactOutput({
    required this.externalId,
    required this.namespace,
    required this.packageName,
    required this.version,
    required this.path,
  });

  /// Transforma a Entidade do Domínio no Output da API
  factory InfraestructureArtifactOutput.fromEntity(ArtifactEntity entity) {
    return InfraestructureArtifactOutput(
      externalId: entity.externalIdValue,
      namespace: entity.namespace,
      packageName: entity.packageNameValue,
      version: entity.versionValue,
      path: entity.path,
    );
  }

  /// Converte para Map pra facilitar o JSON do Controller
  Map<String, dynamic> toJson() {
    return {
      'external_id': externalId,
      'namespace': namespace,
      'package_name': packageName,
      'version': version,
      'path': path,
    };
  }
}
