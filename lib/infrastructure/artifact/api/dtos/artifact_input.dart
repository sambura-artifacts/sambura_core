/// Data Transfer Object (DTO) para entrada de novos artefatos.
/// Centraliza os metadados necessários antes do processamento do binário.
class ArtifactInput {
  final String namespace; // ex: @sambura
  final String repositoryName; // ex: @sambura
  final String packageName; // ex: core-lib
  final String version; // ex: 1.0.0
  final String path; // ex: /libs/core-lib-1.0.0.zip
  final String? filename; // Nome original do arquivo (opcional)

  ArtifactInput({
    required this.repositoryName,
    required this.namespace,
    required this.packageName,
    required this.version,
    required this.path,
    this.filename,
  });

  /// Factory para facilitar se tu estiver recebendo um JSON da Request
  factory ArtifactInput.fromJson(Map<String, dynamic> json) {
    return ArtifactInput(
      repositoryName: json['repository_name'] as String,
      namespace: json['namespace'] as String,
      packageName: json['package_name'] as String,
      version: json['version'] as String,
      path: json['path'] as String,
      filename: json['filename'] as String?,
    );
  }
}
