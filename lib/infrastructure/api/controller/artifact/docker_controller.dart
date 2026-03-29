import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/usecase/artifact/download_and_proxy_artifact_usecase.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';

class DockerController {
  final DownloadAndProxyArtifactUsecase _downloadAndProxyArtifactUsecase;
  final Logger _log = LoggerConfig.getLogger('DockerController');

  DockerController(this._downloadAndProxyArtifactUsecase);

  Future<Response> downloadBlob(
    Request request,
    String repo,
    String name,
    String digest,
  ) async {
    final input = ArtifactInput(
      namespace: repo,
      packageName: name,
      version: digest, // Usando a digest como 'versão' para o download do blob
      fileName: digest,
      metadata: {'digest': digest},
    );

    _log.info(
      'Requisição de download de blob Docker recebida para: $name@$digest',
    );

    final stream = await _downloadAndProxyArtifactUsecase.execute(input);

    if (stream == null) {
      return Response.notFound('Artefato não encontrado');
    }

    return Response.ok(stream);
  }

  Future<Response> checkApi(Request request, String repo) async {
    // A resposta para o check de API do Docker é um 200 OK com cabeçalhos específicos
    return Response.ok(
      '',
      headers: {'Docker-Distribution-Api-Version': 'registry/2.0'},
    );
  }

  Future<Response> getManifest(
    Request request,
    String repo,
    String name,
    String reference,
  ) async {
    // TODO: Implementar busca de manifestos do Docker
    return Response(501, body: 'Busca de manifestos Docker não implementada');
  }
}
