import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:sambura_core/config/app_config.dart';
import 'package:sambura_core/config/logger.dart';

class ProxyPackageMetadataUseCase {
  final Logger _log = LoggerConfig.getLogger('ProxyPackageMetadataUseCase');
  final String remoteHost = 'registry.npmjs.org';

  Future<dynamic> execute(
    String path, {
    required String repoName,
    String? packageName,
    Map<String, String>? queryParams,
  }) async {
    _log.info(
      '🌐 Proxy Request: path=$path, repo=$repoName, pkg=$packageName, params=$queryParams',
    );
    try {
      final uri = Uri.https(remoteHost, path, queryParams);
      _log.info('🌐 Proxy Request: $uri');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        _log.warning(
          '⚠️ Remote Registry respondeu: ${response.statusCode}, ${response.body}',
        );
        return null;
      }

      if (path.endsWith('.tgz') || (packageName?.endsWith('.tgz') ?? false)) {
        return response.bodyBytes;
      }

      final dynamic remoteData = jsonDecode(response.body);

      if (path.contains('search')) {
        return remoteData;
      }

      return _processRemoteMetadata(
        remoteData as Map<String, dynamic>,
        repoName,
      );
    } catch (e, stack) {
      _log.severe('🔥 Erro no Proxy', e, stack);
      return null;
    }
  }

  Map<String, dynamic> _processRemoteMetadata(
    Map<String, dynamic> data,
    String repoName,
  ) {
    _log.info('✅ Processando metadata remoto para: ${data['name']}');
    return _rewriteTarballUrls(data, repoName);
  }

  Map<String, dynamic> _rewriteTarballUrls(
    Map<String, dynamic> data,
    String repoName,
  ) {
    final versions = data['versions'] as Map<String, dynamic>?;
    if (versions == null) return data;

    for (var versionData in versions.values) {
      final dist = versionData['dist'] as Map<String, dynamic>?;
      if (dist != null && dist['tarball'] != null) {
        final String originalUrl = dist['tarball'];
        final fileName = originalUrl.split('/').last;

        dist['tarball'] =
            '${AppConfig.baseUrl}${AppConfig.npmApiPrefix}/$repoName/${data['name']}/-/$fileName';
      }
    }
    return data;
  }
}
