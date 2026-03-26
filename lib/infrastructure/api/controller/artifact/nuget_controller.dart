import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/usecase/artifact/download_npm_artifact_usecase.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';

class NugetController {
  final DownloadNpmArtifactUsecase _downloadAndProxyArtifactUsecase;
  final Logger _log = LoggerConfig.getLogger('NugetController');

  NugetController(this._downloadAndProxyArtifactUsecase);

  Future<Response> downloadPackage(
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
      'Requisição de download NuGet recebida para: ${input.packageName}@${input.version}',
    );

    final stream = await _downloadAndProxyArtifactUsecase.execute(input);

    if (stream == null) {
      return Response.notFound('Artefato não encontrado');
    }

    return Response.ok(stream);
  }

  Future<Response> getServiceIndex(Request request, String repo) async {
    // TODO: Implementar busca de metadados do NuGet (service index)
    return Response(501, body: 'Busca de metadados NuGet não implementada');
  }

  Future<Response> proxyResource(
    Request request,
    String repo,
    String any,
  ) async {
    // TODO: Implementar proxy de recursos do NuGet
    return Response(501, body: 'Proxy de recursos NuGet não implementado');
  }
}
