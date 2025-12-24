import 'dart:async';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/blob_repository.dart';

class DownloadArtifactUsecase {
  final BlobRepository _blobRepo;
  final Logger _log = LoggerConfig.getLogger('DownloadArtifactUsecase');

  DownloadArtifactUsecase(this._blobRepo);

  Future<Stream<List<int>>> execute(String hash) async {
    _log.info('Executando download de blob: ${hash.substring(0, 16)}...');

    try {
      _log.fine('Verificando existência do blob');
      final blob = await _blobRepo.findByHash(hash);

      if (blob == null) {
        _log.severe('✗ Blob não encontrado: ${hash.substring(0, 16)}...');
        throw Exception(
          'Arquivo com hash $hash não foi encontrado no Samburá.',
        );
      }

      _log.info(
        'Blob encontrado: ${blob.sizeBytes} bytes, mime: ${blob.mimeType}',
      );
      _log.fine('Abrindo stream de leitura');
      final stream = await _blobRepo.readAsStream(hash);

      _log.info('✓ Stream de download iniciado com sucesso');
      return stream;
    } catch (e, stack) {
      _log.severe(
        '✗ Erro ao executar download do blob: ${hash.substring(0, 16)}...',
        e,
        stack,
      );
      rethrow;
    }
  }
}
