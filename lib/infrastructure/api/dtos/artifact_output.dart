import 'package:sambura_core/domain/entities/artifact_entity.dart';

/// DTO de saída para informar o sucesso da criação ou detalhes do artefato.
class ArtifactOutput {
  final String externalId;
  final String namespace;
  final String packageName;
  final String version;
  final String path;

  ArtifactOutput({
    required this.externalId,
    required this.namespace,
    required this.packageName,
    required this.version,
    required this.path,
  });

  /// Transforma a Entidade do Domínio no Output da API
  factory ArtifactOutput.fromEntity(ArtifactEntity entity) {
    return ArtifactOutput(
      externalId: entity.externalId,
      namespace: entity.namespace,
      packageName: entity.packageName,
      version: entity.version,
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
