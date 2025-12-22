import 'dart:convert';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:sambura_core/application/usecase/upload_artifact_usecase.dart';

class UploadController {
  final UploadArtifactUsecase _uploadUsecase;

  UploadController(this._uploadUsecase);

  Future<Response> handle(Request request) async {
    final form = request.formData();

    if (form == null) {
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

      await for (final data in form.formData) {
        if (data.name == 'file') {
          fileData = await data.part.readBytes();
          fileName = data.filename;
        } else {
          parameters[data.name] = await data.part.readString();
        }
      }

      final packageName = parameters['package'];
      final version = parameters['version'];

      if (fileData == null || packageName == null || version == null) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'Faltou arquivo, pacote ou versão no formulário!',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      await _uploadUsecase.execute(
        repoName: parameters['repository'] ?? 'default',
        packageName: packageName,
        version: version,
        fileBytes: fileData,
        fileName: fileName ?? 'artifact.tgz',
      );

      return Response.ok(
        jsonEncode({'message': 'Artefato no ninho! 🚀'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro no processamento: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
