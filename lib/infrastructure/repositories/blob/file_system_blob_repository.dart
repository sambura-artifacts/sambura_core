import 'dart:io';
import 'dart:typed_data';
import 'package:async/async.dart';
import 'package:sambura_core/domain/entities/blob_entity.dart';
import 'package:sambura_core/domain/repositories/blob_repository.dart';

class FileSystemBlobRepository implements BlobRepository {
  final String _basePath;

  FileSystemBlobRepository(this._basePath) {
    final dir = Directory(_basePath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      print('📂 [Storage] Diretório base criado: $_basePath');
    }
  }

  @override
  Future<BlobEntity> saveFromStream(Stream<List<int>> byteStream) async {
    print(
      '📥 [Storage] Iniciando stream de upload para o sistema de arquivos...',
    );
    final stopwatch = Stopwatch()..start();

    try {
      // 1. Divide o stream pra calcular o hash e salvar ao mesmo tempo
      final splitter = StreamSplitter(byteStream);
      final metadataStream = splitter.split();
      final storageStream = splitter.split().cast<Uint8List>();
      splitter.close();

      // 2. Gera a entidade (calcula o hash SHA-256)
      final blob = await BlobEntity.fromStream(metadataStream);
      final file = File('$_basePath/${blob.hashValue}');

      // 3. Deduplicação: Só escreve se o arquivo não existir
      if (!await file.exists()) {
        final sink = file.openWrite();
        await sink.addStream(storageStream);
        await sink.close();
        stopwatch.stop();
        print(
          '✅ [Storage] NOVO BLOB: ${blob.hashValue.substring(0, 10)}... | '
          'Tamanho: ${blob.sizeBytes} bytes | Tempo: ${stopwatch.elapsedMilliseconds}ms',
        );
      } else {
        stopwatch.stop();
        print(
          '♻️ [Storage] DEDUPLICAÇÃO: Blob ${blob.hashValue.substring(0, 10)}... já existe. Gravacao ignorada.',
        );
      }

      return blob;
    } catch (e) {
      print('❌ [Storage] ERRO FATAL ao gravar no disco: $e');
      rethrow;
    }
  }

  @override
  Future<Stream<Uint8List>> readAsStream(String hashValue) async {
    print('📤 [Storage] Lendo blob: ${hashValue.substring(0, 10)}...');
    final file = File('$_basePath/$hashValue');

    if (!await file.exists()) {
      print('⚠️ [Storage] Blob não encontrado no caminho: ${file.path}');
      throw Exception('📦 Blob não encontrado no disco: $hashValue');
    }

    return file.openRead().cast<Uint8List>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
