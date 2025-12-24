import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:sambura_core/config/app_config.dart';
import 'package:sambura_core/config/logger.dart';

class ProxyPackageMetadataUseCase {
  final Logger _log = LoggerConfig.getLogger('ProxyPackageMetadataUseCase');
  final String remoteRegistry = 'https://registry.npmjs.org';

  Future<dynamic> execute(
    String packageName, {
    required String repoName,
  }) async {
    try {
      final encodedName = packageName.replaceFirst('/', '%2f');

      final response = await http.get(
        Uri.parse('$remoteRegistry/$encodedName'),
      );

      if (response.statusCode != 200) return null;

      if (packageName.endsWith('.tgz')) return response.bodyBytes;

      final Map<String, dynamic> remoteData = jsonDecode(response.body);

      // CENTRALIZANDO: Chama o process que por sua vez chama o rewrite
      return _processRemoteMetadata(remoteData, repoName);
    } catch (e) {
      _log.severe('🔥 Erro no Proxy', e);
      return null;
    }
  }

  Map<String, dynamic> _processRemoteMetadata(
    Map<String, dynamic> data,
    String repoName,
  ) {
    _log.info('✅ Processando metadata remoto para: ${data['name']}');

    final processedData = _rewriteTarballUrls(data, repoName);

    return processedData;
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
