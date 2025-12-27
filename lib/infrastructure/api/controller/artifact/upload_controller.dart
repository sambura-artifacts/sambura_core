import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:sambura_core/application/usecase/artifact/check_artifact_exists_usecase.dart';
import 'package:sambura_core/application/usecase/usecases.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/exceptions/domain_exception.dart';
import 'package:sambura_core/domain/utils/security_validator.dart';
import 'package:sambura_core/infrastructure/exceptions/infrastructure_exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';

class UploadController {
  final UploadArtifactUsecase _uploadUsecase;
  final CheckArtifactExistsUseCase _checkArtifactExistsUseCase;
  final Logger _log = LoggerConfig.getLogger('UploadController');

  UploadController(this._uploadUsecase, this._checkArtifactExistsUseCase);

  Future<Response> handle(Request request) async {
    final contentType = request.headers['content-type'] ?? '';

    _log.info('Recebendo upload. Tipo: $contentType');

    final data = await _parseUploadData(request, contentType);
    _log.fine(
      'Payload extraído: ${data.packageName}@${data.version} em ${data.repoName}',
    );

    SecurityValidator.validateGenericInput(data.repoName);
    SecurityValidator.validatePackagePath(data.packageName);

    final exists = await _checkArtifactExistsUseCase.execute(
      namespace: data.repoName,
      name: data.packageName,
      version: data.version,
    );

    if (exists) {
      _log.warning('Conflito: ${data.packageName}@${data.version} já existe.');
      throw VersionConflictException(data.packageName, data.version);
    }

    _log.info('Iniciando persistência do artefato: ${data.fileName}');
    await _uploadUsecase.execute(
      repoName: data.repoName,
      packageName: data.packageName,
      version: data.version,
      fileBytes: data.fileBytes,
      fileName: data.fileName,
    );

    _log.info(
      'Upload concluído com sucesso: ${data.packageName}@${data.version}',
    );

    return Response.ok(
      jsonEncode({'ok': true, 'message': 'Publicado com sucesso!'}),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<_UploadData> _parseUploadData(Request request, String type) async {
    final repoFromUrl = request.params['repo'] ?? 'npm-registry';

    if (type.contains('application/json')) {
      final payload = jsonDecode(await request.readAsString());
      final attachments = payload['_attachments'] as Map? ?? {};

      if (attachments.isEmpty) {
        _log.warning('Upload NPM falhou: _attachments vazio.');
        throw PackageNameException('Nenhum arquivo enviado');
      }

      final fileName = attachments.keys.first;
      final fileBytes = base64Decode(
        attachments[fileName]['data'].toString().replaceAll('\n', '').trim(),
      );

      return _UploadData(
        packageName: payload['name'],
        version: payload['dist-tags']['latest'],
        repoName: repoFromUrl,
        fileName: fileName,
        fileBytes: fileBytes,
      );
    }

    if (type.contains('multipart/form-data')) {
      final form = request.formData()!;
      final params = <String, String>{};
      Uint8List? fileBytes;
      String? fileName;

      await for (final part in form.formData) {
        if (part.name == 'file') {
          fileBytes = await part.part.readBytes();
          fileName = part.filename;
        } else {
          params[part.name] = await part.part.readString();
        }
      }

      if (fileBytes == null) {
        _log.warning('Upload Multipart falhou: campo "file" ausente.');
        throw ArtifactNotFoundException('Arquivo ausente');
      }

      return _UploadData(
        packageName: params['package'] ?? '',
        version: params['version'] ?? '',
        repoName: params['repository'] ?? repoFromUrl,
        fileName: fileName ?? 'artifact.tgz',
        fileBytes: fileBytes,
      );
    }

    _log.severe('Content-Type não suportado: $type');
    throw ControllerException('Formato de conteúdo não suportado: $type');
  }
}

class _UploadData {
  final String packageName;
  final String version;
  final String repoName;
  final String fileName;
  final Uint8List fileBytes;

  _UploadData({
    required this.packageName,
    required this.version,
    required this.repoName,
    required this.fileName,
    required this.fileBytes,
  });
}
