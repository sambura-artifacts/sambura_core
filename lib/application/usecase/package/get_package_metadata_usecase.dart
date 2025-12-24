import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';

class GetPackageMetadataUseCase {
  final ArtifactRepository _artifactRepo;
  final Logger _log = LoggerConfig.getLogger('GetPackageMetadataUseCase');

  GetPackageMetadataUseCase(this._artifactRepo);

  Future<Map<String, dynamic>?> execute(
    String repoName,
    String packageName,
  ) async {
    _log.info('Buscando metadata: repo=$repoName, package=$packageName');

    try {
      _log.fine('Consultando todas as versões do pacote');
      final artifacts = await _artifactRepo.findAllVersions(
        repoName,
        packageName,
      );

      if (artifacts.isEmpty) {
        _log.warning(
          '✗ Nenhuma versão encontrada para: $repoName/$packageName',
        );
        return null;
      }

      _log.info('Encontradas ${artifacts.length} versões do pacote');
      final versions = <String, dynamic>{};

      for (var a in artifacts) {
        final blob = a.blob;
        if (blob == null) {
          _log.warning('Blob nulo para artefato ${a.version}, pulando');
          continue;
        }

        final hexHash = blob.hashValue;
        final bytes = hex.decode(hexHash);
        final base64Hash = base64.encode(bytes);
        final integrity = "sha256-$base64Hash";

        versions[a.versionValue] = {
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

      if (versions.isEmpty) {
        _log.warning('✗ Nenhuma versão válida (com blob) encontrada');
        return null;
      }

      final latestVersion = artifacts.last.version;
      _log.info(
        '✓ Metadata gerado: ${versions.length} versões, latest=$latestVersion',
      );

      return {
        "name": packageName,
        "dist-tags": {"latest": latestVersion},
        "versions": versions,
      };
    } catch (e, stack) {
      _log.severe(
        '✗ Erro ao buscar metadata de $repoName/$packageName',
        e,
        stack,
      );
      rethrow;
    }
  }
}
