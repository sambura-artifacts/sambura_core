import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/usecase/artifact/download_and_proxy_artifact_usecase.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';

class NpmController {
  final DownloadAndProxyArtifactUsecase _downloadAndProxyArtifactUsecase;
  final Logger _log = LoggerConfig.getLogger('NpmController');

  NpmController(this._downloadAndProxyArtifactUsecase);

  Future<Response> downloadTarball(
    Request request,
    String repo,
    String package,
    String filename,
  ) async {
    // A variável packageName é usada implicitamente pelo `package` que vem da rota
    // que pode conter um escopo. Vamos manter a extração para consistência.
    // ex: express-4.17.1.tgz -> package=express, version=4.17.1
    final parts = filename.substring(0, filename.lastIndexOf('.')).split('-');
    final version = parts.removeLast();
    // final packageName = parts.join('-'); // A variável `package` da rota já contém o nome correto

    final input = ArtifactInput(
      namespace: repo,
      packageName: package, // pode ter @scope/pkg
      version: version,
      fileName: filename,
    );

    _log.info(
      'Requisição de download NPM recebida para: ${input.packageName}@${input.version}',
    );

    final stream = await _downloadAndProxyArtifactUsecase.execute(input);

    if (stream == null) {
      return Response.notFound('Artefato não encontrado');
    }

    return Response.ok(stream);
  }

  Future<Response> getPackageMetadata(
    Request request,
    String repo,
    String packageName,
  ) async {
    // TODO: Implementar busca de metadados do NPM (package.json)
    return Response(501, body: 'Busca de metadados NPM não implementada');
  }
}
