import 'package:logging/logging.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/config/logger.dart';

class PypiProxyUseCase {
  final HttpClientPort _client;
  final String remoteHost = 'pypi.org';
  final Logger _log = LoggerConfig.getLogger('PypiProxyUseCase');

  PypiProxyUseCase(this._client);

  /// Executa o proxy de busca para o PyPI (Simple API ou Download)
  /// path: 'simple/requests/' ou 'packages/.../requests-2.31.0-py3-none-any.whl'
  Future<dynamic> execute(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    _log.info('🌐 PyPI Proxy Request: $path');

    try {
      final uri = Uri.https(remoteHost, path, queryParams);
      _log.info('🌐 Proxy Request URI: $uri');

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        // Se for HTML (Simple API), retornamos a string
        if (path.contains('/simple/')) {
          return response.body;
        }
        // Se for binário (whl, tar.gz), retornamos os bytes
        return response.bodyBytes;
      }

      _log.warning('⚠️ PyPI Proxy retornou status: ${response.statusCode}');
      return null;
    } catch (e, stack) {
      _log.severe('🔥 Erro no PyPI Proxy', e, stack);
      return null;
    }
  }
}
