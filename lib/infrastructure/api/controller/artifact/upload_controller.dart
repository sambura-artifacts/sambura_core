import 'dart:convert';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:sambura_core/application/usecase/artifact/upload_artifact_usecase.dart';

class UploadController {
  final UploadArtifactUsecase _uploadUsecase;
  final Logger _log = LoggerConfig.getLogger('UploadController');

  UploadController(this._uploadUsecase);

  Future<Response> handle(Request request) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _log.info('[REQ:$requestId] POST /upload - Iniciando upload multipart');

    final form = request.formData();

    if (form == null) {
      _log.warning(
        '[REQ:$requestId] ✗ Request sem formato multipart/form-data',
      );
      return Response.badRequest(
        body: jsonEncode({
          'error': 'Manda no formato multipart/form-data, cria!',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    try {
      final parameters = <String, dynamic>{};
      Uint8List? fileData;
      String? fileName;

      _log.fine('[REQ:$requestId] Processando dados do formulário multipart');
      await for (final data in form.formData) {
        if (data.name == 'file') {
          fileData = await data.part.readBytes();
          fileName = data.filename;
          _log.fine(
            '[REQ:$requestId] Arquivo recebido: $fileName (${fileData.length} bytes)',
          );
        } else {
          parameters[data.name] = await data.part.readString();
        }
      }

      final packageName = parameters['package'];
      final version = parameters['version'];
      final repoName = parameters['repository'] ?? 'default';

      if (fileData == null || packageName == null || version == null) {
        _log.warning(
          '[REQ:$requestId] ✗ Parâmetros incompletos: file=${fileData != null}, package=$packageName, version=$version',
        );
        return Response.badRequest(
          body: jsonEncode({
            'error': 'Faltou arquivo, pacote ou versão no formulário!',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      _log.info(
        '[REQ:$requestId] Processando upload: repo=$repoName, package=$packageName@$version, size=${fileData.length} bytes',
      );

      await _uploadUsecase.execute(
        repoName: repoName,
        packageName: packageName,
        version: version,
        fileBytes: fileData,
        fileName: fileName ?? 'artifact.tgz',
      );

      _log.info(
        '[REQ:$requestId] ✓ Upload concluído com sucesso: $packageName@$version',
      );
      return Response.ok(
        jsonEncode({'message': 'Artefato no ninho! 🚀'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stack) {
      _log.severe(
        '[REQ:$requestId] ✗ Erro no processamento do upload',
        e,
        stack,
      );
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro no processamento: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
