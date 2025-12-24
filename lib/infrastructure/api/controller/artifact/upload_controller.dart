import 'dart:convert';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';
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
    final contentType = request.headers['content-type'] ?? '';

    _log.info(
      '[REQ:$requestId] ${request.method} /upload - Content-Type: $contentType',
    );

    try {
      // 1. Fluxo NPM Publish (JSON + Base64)
      if (contentType.contains('application/json')) {
        return await _handleNpmPublish(request, requestId);
      }

      // 2. Fluxo Manual (Multipart/Form-Data)
      if (contentType.contains('multipart/form-data')) {
        return await _handleMultipartUpload(request, requestId);
      }

      return Response.badRequest(
        body: jsonEncode({
          'error': 'Formato não suportado. Use JSON (NPM) ou Multipart.',
        }),
        headers: {'content-type': 'application/json'},
      );
    } on ServerException catch (e) {
      // Código 23505 é Unique Violation no Postgres
      if (e.code == '23505') {
        _log.warning('⚠️ Tentativa de sobrepôr versão existente.');
        return Response(
          403, // Forbidden é o padrão NPM para conflito de versão
          body: jsonEncode({
            'error': 'forbidden',
            'reason':
                'You cannot publish over the previously published versions.',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
      rethrow;
    } catch (e, stack) {
      _log.severe('[REQ:$requestId] ✗ Erro crítico no upload', e, stack);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro interno: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Processa o PUT/POST oficial do cliente NPM
  Future<Response> _handleNpmPublish(Request request, String requestId) async {
    _log.fine('[REQ:$requestId] Processando payload JSON do NPM');

    final body = await request.readAsString();
    final payload = jsonDecode(body);

    final String packageName = payload['name'];
    final String version = payload['dist-tags']['latest'];
    final Map<String, dynamic> attachments = payload['_attachments'] ?? {};

    if (attachments.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Nenhum attachment encontrado no JSON'}),
      );
    }

    final fileName = attachments.keys.first;
    final String base64Data = attachments[fileName]['data'];
    final Uint8List fileBytes = base64Decode(
      base64Data.replaceAll('\n', '').trim(),
    );

    _log.info('[REQ:$requestId] NPM Publish: $packageName@$version');

    await _uploadUsecase.execute(
      repoName: 'npm-registry', // Pode ser extraído da URL via request.context
      packageName: packageName,
      version: version,
      fileBytes: fileBytes,
      fileName: fileName,
    );

    return Response.ok(
      jsonEncode({'ok': true, 'message': 'Pacote publicado no Samburá!'}),
      headers: {'content-type': 'application/json'},
    );
  }

  /// Processa uploads via formulário (scripts ou UI)
  Future<Response> _handleMultipartUpload(
    Request request,
    String requestId,
  ) async {
    _log.fine('[REQ:$requestId] Processando upload multipart');

    final form = request.formData()!;
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
    final repoName = parameters['repository'] ?? 'default';

    if (fileData == null || packageName == null || version == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Faltam campos obrigatórios no multipart'}),
      );
    }

    await _uploadUsecase.execute(
      repoName: repoName,
      packageName: packageName,
      version: version,
      fileBytes: fileData,
      fileName: fileName ?? 'artifact.tgz',
    );

    return Response.ok(
      jsonEncode({'message': 'Artefato recebido via multipart! 🚀'}),
      headers: {'content-type': 'application/json'},
    );
  }
}
