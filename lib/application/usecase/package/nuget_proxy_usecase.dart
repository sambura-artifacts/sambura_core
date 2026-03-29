import 'package:logging/logging.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/config/logger.dart';

class NugetProxyUseCase {
  final HttpClientPort _client;
  final String remoteHost = 'api.nuget.org';
  final Logger _log = LoggerConfig.getLogger('NugetProxyUseCase');

  NugetProxyUseCase(this._client);

  /// Executa o proxy de busca para o NuGet V3 API
  /// path: 'v3/index.json' ou 'v3-flatcontainer/package/version/package.version.nupkg'
  Future<dynamic> execute(
    String path, {
    String? host,
    Map<String, String>? queryParams,
  }) async {
    final targetHost = host ?? remoteHost;
    _log.info('🌐 NuGet Proxy Request: $path (Host: $targetHost)');

    try {
      final uri = Uri.https(targetHost, path, queryParams);
      _log.info('🌐 Proxy Request URI: $uri');

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        // Se for JSON (Index, Registration), retornamos a string
        if (path.endsWith('.json') || !path.contains('.')) {
          return response.body;
        }
        // Se for binário (.nupkg, .snupkg), retornamos os bytes
        return response.bodyBytes;
      }

      _log.warning('⚠️ NuGet Proxy retornou status: ${response.statusCode}');
      return null;
    } catch (e, stack) {
      _log.severe('🔥 Erro no NuGet Proxy', e, stack);
      return null;
    }
  }
}
