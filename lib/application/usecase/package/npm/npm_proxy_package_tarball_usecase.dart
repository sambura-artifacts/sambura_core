import 'dart:async';
import 'dart:typed_data';
import 'package:async/async.dart'; // Pacote útil para Splitter
import 'package:logging/logging.dart';
import 'package:sambura_core/application/ports/barrel.dart';

class ProxyPackageTarballUseCase {
  final HttpClientPort _httpClient;
  final StoragePort _storage;
  final Logger _log = Logger('ProxyPackageTarballUseCase');

  ProxyPackageTarballUseCase(this._httpClient, this._storage);

  Future<Stream<List<int>>> execute({
    required String remoteUrl,
    required String storagePath,
  }) async {
    if (await _storage.exists(storagePath)) {
      _log.info('📦 Cache Hit: Servindo $storagePath do Silo local');
      return _storage.retrieve(storagePath);
    }

    _log.info('🌐 Cache Miss: Baixando de $remoteUrl');

    final response = await _httpClient.stream(Uri.parse(remoteUrl));
    final splitter = StreamSplitter<Uint8List>(response.stream);
    final userStream = splitter.split();
    final storageStream = splitter.split();
    splitter.close();

    _saveToStorage(storageStream, storagePath, response.length ?? 0);

    return userStream;
  }

  Future<void> _saveToStorage(
    Stream<List<int>> stream,
    String path,
    int size,
  ) async {
    try {
      final uint8Stream = stream.map((chunk) => Uint8List.fromList(chunk));
      await _storage.store(
        path: path,
        stream: uint8Stream,
        sizeBytes: size,
        contentType: 'application/x-tgz', // Padrão para .tgz
      );
      _log.info('✅ Mirroring concluído: $path');
    } catch (e) {
      _log.severe('❌ Falha ao persistir cache no Silo: $path', e);
    }
  }
}
