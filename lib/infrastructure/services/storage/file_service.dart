import 'dart:async';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:minio/minio.dart';

class FileService {
  final Minio _minio;
  final String _bucket;
  final _log = Logger('FileService');

  FileService(this._minio, this._bucket);

  /// Retorna o Stream de bytes do arquivo direto do Storage.
  /// Essencial para performance no download via NPM.
  Future<Stream<List<int>>> getFileStream(String path) async {
    try {
      _log.fine('📥 Solicitando stream do objeto: $_bucket/$path');

      return await _minio.getObject(_bucket, path);
    } catch (e, stack) {
      _log.severe('💥 Erro ao buscar stream no Storage: $path', e, stack);
      throw Exception('Não foi possível ler o arquivo no Storage.');
    }
  }

  /// Faz o upload de um arquivo.
  Future<void> uploadFile({
    required String path,
    required Stream<Uint8List> stream,
    required int size,
    String? contentType,
  }) async {
    try {
      _log.info('📤 Fazendo upload para: $_bucket/$path ($size bytes)');

      await _minio.putObject(
        _bucket,
        path,
        stream,
        size: size,
        metadata: {'Content-Type': contentType ?? 'application/octet-stream'},
      );

      _log.fine('✅ Upload concluído com sucesso.');
    } catch (e, stack) {
      _log.severe('💥 Erro no upload para o Storage', e, stack);
      throw Exception('Falha ao persistir arquivo no Storage.');
    }
  }

  /// Remove um arquivo (Revogação/Delete)
  Future<void> deleteFile(String path) async {
    try {
      await _minio.removeObject(_bucket, path);
      _log.info('🗑️ Arquivo removido do storage: $path');
    } catch (e) {
      _log.warning('⚠️ Falha ao deletar arquivo: $path');
    }
  }
}
