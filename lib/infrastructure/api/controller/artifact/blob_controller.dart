import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:sambura_core/domain/repositories/blob_repository.dart';
import 'package:sambura_core/infrastructure/api/presenter/error_presenter.dart';

class BlobController {
  final BlobRepository _blobRepo;
  final Logger _log = LoggerConfig.getLogger('BlobController');

  BlobController(this._blobRepo);

  /// GET /blobs/:hash
  Future<Response> download(Request request, String hash) async {
    final baseUrl = request.requestedUri.origin;
    _log.info('Download solicitado para blob: ${hash.substring(0, 12)}...');

    try {
      final blob = await _blobRepo.findByHash(hash);

      if (blob == null) {
        _log.warning('Blob não encontrado: $hash');
        return ErrorPresenter.notFound(
          "O conteúdo binário solicitado não foi localizado no servidor.",
          request.url.path,
          baseUrl,
        );
      }

      _log.fine('Blob encontrado, iniciando stream de dados');
      final stream = await _blobRepo.readAsStream(hash);

      _log.info(
        'Download iniciado: ${blob.sizeBytes} bytes (${blob.mimeType})',
      );

      return Response.ok(
        stream,
        headers: {
          'Content-Type': blob.mimeType,
          'Content-Length': blob.sizeBytes.toString(),
          'Content-Disposition': 'attachment; filename="${blob.hashValue}"',
        },
      );
    } catch (e, stack) {
      _log.severe('Erro ao processar download do blob: $hash', e, stack);
      return ErrorPresenter.internalServerError(
        "Falha ao processar o download do arquivo binário.",
        request.url.path,
        baseUrl,
        error: e,
        stack: stack,
      );
    }
  }
}
