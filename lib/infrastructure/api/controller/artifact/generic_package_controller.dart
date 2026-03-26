import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:sambura_core/application/usecase/artifact/download_npm_artifact_usecase.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';

class GenericPackageController {
  final DownloadNpmArtifactUsecase _downloadAndProxyArtifactUsecase;
  final Logger _log = LoggerConfig.getLogger('GenericPackageController');

  GenericPackageController(this._downloadAndProxyArtifactUsecase);

  Future<Response> download(
    Request request,
    String repo,
    String package,
    String version,
    String filename,
  ) async {
    final input = ArtifactInput(
      namespace: repo,
      packageName: package,
      version: version,
      fileName: filename,
    );

    _log.info(
      'Requisição de download recebida para: $repo/$package@$version/$filename',
    );

    final stream = await _downloadAndProxyArtifactUsecase.execute(input);

    if (stream == null) {
      return Response.notFound('Artefato não encontrado');
    }

    return Response.ok(stream);
  }

  Future<Response> downloadScoped(
    Request request,
    String repo,
    String scope,
    String package,
    String version,
    String filename,
  ) async {
    final fullPackageName = '$scope/$package';
    return download(request, repo, fullPackageName, version, filename);
  }
}
