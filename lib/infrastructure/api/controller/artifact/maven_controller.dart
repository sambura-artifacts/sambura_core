import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/usecase/artifact/download_and_proxy_artifact_usecase.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';

class MavenController {
  final DownloadAndProxyArtifactUsecase _downloadAndProxyArtifactUsecase;
  final Logger _log = LoggerConfig.getLogger('MavenController');

  MavenController(this._downloadAndProxyArtifactUsecase);

  Future<Response> downloadArtifact(
    Request request,
    String repo,
    String groupId,
    String artifactId,
    String version,
    String filename,
  ) async {
    final input = ArtifactInput(
      namespace: repo,
      packageName: '$groupId:$artifactId',
      version: version,
      fileName: filename,
      metadata: {'groupId': groupId, 'artifactId': artifactId},
    );

    _log.info(
      'Requisição de download Maven recebida para: ${input.packageName}@${input.version}',
    );

    final stream = await _downloadAndProxyArtifactUsecase.execute(input);

    if (stream == null) {
      return Response.notFound('Artefato não encontrado');
    }

    return Response.ok(stream);
  }

  Future<Response> getMetadata(
    Request request,
    String repo,
    String groupId,
    String artifactId,
  ) async {
    // TODO: Implementar busca de metadados do Maven (maven-metadata.xml)
    return Response(501, body: 'Busca de metadados Maven não implementada');
  }
}
