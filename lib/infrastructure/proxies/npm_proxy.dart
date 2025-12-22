import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/blob_repository.dart';
import 'package:sambura_core/domain/entities/blob_entity.dart';

class NpmProxy {
  final BlobRepository _blobRepository;
  final String _registryUrl = "https://registry.npmjs.org";
  final Logger _log = LoggerConfig.getLogger('NpmProxyService');

  NpmProxy(this._blobRepository);

  Future<BlobEntity> fetchAndStore(String packageName, String version) async {
    final client = http.Client();
    final url = Uri.parse(
      "$_registryUrl/$packageName/-/$packageName-$version.tgz",
    );
    final stopwatch = Stopwatch()..start();

    _log.info('Solicitando upstream: $url');

    try {
      final request = http.Request('GET', url);
      final http.StreamedResponse response = await client.send(request);

      if (response.statusCode != 200) {
        _log.warning(
          'Registry retornou erro ${response.statusCode} para $packageName@$version',
        );
        throw Exception("Falha no Upstream NPM: ${response.statusCode}");
      }

      final contentLength = response.contentLength ?? 0;
      final sizeDesc = contentLength > 0
          ? '${(contentLength / 1024).toStringAsFixed(2)} KB'
          : 'tamanho desconhecido';

      _log.info('Download iniciado | Tamanho esperado: $sizeDesc');

      // O segredo pra não dar erro de Sink: asBroadcastStream resolve o problema de múltiplas leituras
      final Stream<List<int>> cleanStream = response.stream.asBroadcastStream();

      // Salva no storage (Silo/FileSystem)
      _log.fine('Salvando blob a partir do stream de resposta');
      final blob = await _blobRepository.saveFromStream(cleanStream);

      stopwatch.stop();
      _log.info(
        'Sincronização concluída | Hash: ${blob.hashValue.substring(0, 12)}... | Tempo: ${stopwatch.elapsedMilliseconds}ms',
      );

      return blob;
    } catch (e, stack) {
      _log.severe(
        'Erro fatal ao fazer fetch de $packageName@$version',
        e,
        stack,
      );
      rethrow;
    } finally {
      client.close();
    }
  }
}
