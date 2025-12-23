import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';

class GetPackageMetadataUseCase {
  final ArtifactRepository _artifactRepo;

  GetPackageMetadataUseCase(this._artifactRepo);

  Future<Map<String, dynamic>?> execute(
    String repoName,
    String packageName,
  ) async {
    final artifacts = await _artifactRepo.findAllVersions(
      repoName,
      packageName,
    );

    if (artifacts.isEmpty) return null;

    final versions = <String, dynamic>{};
    for (var a in artifacts) {
      final blob = a.blob;
      if (blob == null) continue;

      final hexHash = blob.hashValue;

      print(hexHash);

      final bytes = hex.decode(hexHash);
      final base64Hash = base64.encode(bytes);
      final integrity = "sha256-$base64Hash";

      versions[a.version] = {
        "name": packageName,
        "version": a.version,
        "dist": {
          "tarball":
              "http://localhost:8080/api/v1/download/$repoName/$packageName/${a.version}",
          "integrity": integrity,
          "shasum": hexHash,
        },
      };
    }

    if (versions.isEmpty) return null;

    return {
      "name": packageName,
      "dist-tags": {"latest": artifacts.last.version},
      "versions": versions,
    };
  }
}
