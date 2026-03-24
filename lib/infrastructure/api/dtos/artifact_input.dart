/// Data Transfer Object (DTO) para entrada de novos artefatos.
/// Centraliza os metadados necessários antes do processamento do binário.
class ArtifactInput {
  final String namespace; // ex: npm-private
  final String packageName; // ex: core-lib ou @scope/core-lib
  final String version; // ex: 1.0.0
  final String?
  fileName; // Nome original do arquivo (opcional, ex: core-lib-1.0.0.tgz)
  final Map<String, dynamic> metadata; // Metadados específicos do tipo de repo

  ArtifactInput({
    required this.namespace,
    required this.packageName,
    required this.version,
    this.fileName,
    this.metadata = const {},
  });
}
