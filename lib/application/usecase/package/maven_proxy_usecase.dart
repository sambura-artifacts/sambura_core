import 'package:logging/logging.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/config/logger.dart';

class MavenProxyUseCase {
  final HttpClientPort _client;
  final String remoteHost = 'repo1.maven.org'; // Maven Central
  final Logger _log = LoggerConfig.getLogger('MavenProxyUseCase');

  MavenProxyUseCase(this._client);

  /// Executa o proxy de busca para o Maven Central.
  /// path: 'org/apache/maven/maven-model/3.8.1/maven-model-3.8.1.jar'
  Future<dynamic> execute(String path) async {
    _log.info('🌐 Maven Proxy Request: $path');

    try {
      final baseUri = Uri.https(remoteHost, '/maven2/$path');
      _log.info('🌐 Proxy Request: $baseUri');

      final response = await _client.get(baseUri);

      if (response.statusCode == 200) {
        // Se for XML (metadata ou pom), retornamos a string
        if (path.endsWith('.xml') || path.endsWith('.pom')) {
          return response.body;
        }
        // Se for binário (jar, war, etc), retornamos os bytes
        return response.bodyBytes;
      }

      _log.warning('⚠️ Maven Proxy retornou status: ${response.statusCode}');
      return null;
    } catch (e, stack) {
      _log.severe('🔥 Erro no Maven Proxy', e, stack);
      return null;
    }
  }
}
