import 'package:sambura_core/domain/value_objects/package_name.dart';
import 'package:sambura_core/domain/value_objects/version.dart';

/// DTO de entrada para criação de artefato.
/// Separa claramente os dados de entrada da lógica de domínio.
class CreateArtifactInput {
  final String repositoryName;
  final PackageName packageName;
  final Version version;
  final String path;
  final Stream<List<int>> dataStream;

  const CreateArtifactInput({
    required this.repositoryName,
    required this.packageName,
    required this.version,
    required this.path,
    required this.dataStream,
  });

  factory CreateArtifactInput.fromRaw({
    required String repositoryName,
    required String packageName,
    required String version,
    required String path,
    required Stream<List<int>> dataStream,
  }) {
    return CreateArtifactInput(
      repositoryName: repositoryName,
      packageName: PackageName(packageName),
      version: Version.create(version),
      path: path,
      dataStream: dataStream,
    );
  }
}

/// DTO de saída para criação de artefato.
class CreateArtifactOutput {
  final String artifactId;
  final String packageName;
  final String version;
  final String downloadUrl;
  final int sizeBytes;
  final DateTime createdAt;

  const CreateArtifactOutput({
    required this.artifactId,
    required this.packageName,
    required this.version,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'artifact_id': artifactId,
    'package_name': packageName,
    'version': version,
    'download_url': downloadUrl,
    'size_bytes': sizeBytes,
    'created_at': createdAt.toIso8601String(),
  };
}
