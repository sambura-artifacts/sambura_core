import 'package:logging/logging.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/config/logger.dart';

class DockerProxyUseCase {
  final HttpClientPort _client;
  final String remoteHost = 'registry-1.docker.io';
  final Logger _log = LoggerConfig.getLogger('DockerProxyUseCase');

  DockerProxyUseCase(this._client);

  /// Executa o proxy de busca para o Docker Registry API V2
  /// path: 'v2/library/node/manifests/latest' ou 'v2/library/node/blobs/sha256:...'
  Future<dynamic> execute(String path, {Map<String, String>? headers}) async {
    _log.info('🌐 Docker Proxy Request: $path');

    try {
      final uri = Uri.https(remoteHost, path);

      // Docker Hub requer autenticação via Bearer Token mesmo para imagens públicas
      // Para este MVP, vamos assumir que o HttpClientAdapter lida com redirecionamentos
      // e autenticação anônima se necessário, ou injetar o token aqui.
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        // Se for manifesto (JSON), retornamos a string
        if (path.contains('/manifests/')) {
          return response.body;
        }
        // Se for blob (camada), retornamos os bytes
        return response.bodyBytes;
      }

      _log.warning('⚠️ Docker Proxy retornou status: ${response.statusCode}');
      return null;
    } catch (e, stack) {
      _log.severe('🔥 Erro no Docker Proxy', e, stack);
      return null;
    }
  }
}
