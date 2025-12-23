import 'package:sambura_core/domain/value_objects/package_name.dart';
import 'package:sambura_core/domain/value_objects/version.dart';

/// DTO de entrada para buscar artefato.
class GetArtifactInput {
  final String repositoryName;
  final PackageName packageName;
  final Version version;

  const GetArtifactInput({
    required this.repositoryName,
    required this.packageName,
    required this.version,
  });

  factory GetArtifactInput.fromRaw({
    required String repositoryName,
    required String packageName,
    required String version,
  }) {
    return GetArtifactInput(
      repositoryName: repositoryName,
      packageName: PackageName.create(packageName),
      version: Version.create(version),
    );
  }
}

/// DTO de saída para buscar artefato.
class GetArtifactOutput {
  final String artifactId;
  final String packageName;
  final String version;
  final String downloadUrl;
  final int sizeBytes;
  final String hash;
  final String mimeType;
  final DateTime createdAt;
  final bool isFromCache;

  const GetArtifactOutput({
    required this.artifactId,
    required this.packageName,
    required this.version,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.hash,
    required this.mimeType,
    required this.createdAt,
    this.isFromCache = false,
  });

  Map<String, dynamic> toJson() => {
    'artifact_id': artifactId,
    'package_name': packageName,
    'version': version,
    'download_url': downloadUrl,
    'size_bytes': sizeBytes,
    'hash': hash,
    'mime_type': mimeType,
    'created_at': createdAt.toIso8601String(),
    'cached': isFromCache,
  };
}
