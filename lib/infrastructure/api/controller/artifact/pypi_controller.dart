import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/usecase/artifact/download_npm_artifact_usecase.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';

class PypiController {
  final DownloadNpmArtifactUsecase _downloadAndProxyArtifactUsecase;
  final Logger _log = LoggerConfig.getLogger('PypiController');

  PypiController(this._downloadAndProxyArtifactUsecase);

  Future<Response> downloadArtifact(
    Request request,
    String repo,
    String path,
  ) async {
    // A estrutura do PyPI é mais complexa, o path contém tudo
    // ex: /packages/aa/bb/cc/somepackage-1.0.0-py3-none-any.whl
    final parts = path.split('/');
    final filename = parts.last;
    final packageParts = filename.split('-');
    final packageName = packageParts[0];
    final version = packageParts[1];

    final input = ArtifactInput(
      namespace: repo,
      packageName: packageName,
      version: version,
      fileName: filename,
      metadata: {'fullPath': path},
    );

    _log.info(
      'Requisição de download PyPI recebida para: ${input.packageName}@${input.version}',
    );

    final stream = await _downloadAndProxyArtifactUsecase.execute(input);

    if (stream == null) {
      return Response.notFound('Artefato não encontrado');
    }

    return Response.ok(stream);
  }

  Future<Response> getSimpleMetadata(
    Request request,
    String repo,
    String package,
  ) async {
    // TODO: Implementar busca de metadados do PyPI (simple index)
    return Response(501, body: 'Busca de metadados PyPI não implementada');
  }
}
