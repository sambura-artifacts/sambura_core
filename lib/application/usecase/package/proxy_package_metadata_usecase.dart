import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';

class ProxyPackageMetadataUseCase {
  final Logger _log = LoggerConfig.getLogger('ProxyPackageMetadataUseCase');
  final String remoteRegistry = 'https://registry.npmjs.org';

  Future<dynamic> execute(String packageName) async {
    _log.info('🔍 Proxy: Buscando pacote externo: $packageName');

    try {
      // O NPM exige encoding apenas da barra entre scope e nome
      final encodedName = packageName.replaceFirst('/', '%2f');
      final response = await http.get(
        Uri.parse('$remoteRegistry/$encodedName'),
      );

      if (response.statusCode == 404) {
        _log.warning(
          '⚠️ Pacote não encontrado no registro oficial: $packageName',
        );
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Erro ao consultar registro remoto: ${response.statusCode}',
        );
      }

      // 1. CHECAGEM DE TARBALL: Se for binário, retorna os bytes sem tentar decode JSON
      if (packageName.endsWith('.tgz')) {
        _log.info('📦 Proxy: Binário detectado (.tgz). Retornando bytes.');
        return response.bodyBytes;
      }

      // 2. METADATA: Se não for binário, processa como JSON
      final Map<String, dynamic> remoteData = jsonDecode(response.body);
      return _processRemoteMetadata(remoteData);
    } catch (e, stack) {
      _log.severe('🔥 Erro no Proxy para $packageName', e, stack);
      return null;
    }
  }

  Map<String, dynamic> _processRemoteMetadata(Map<String, dynamic> data) {
    _log.info('✅ Metadata remoto obtido para ${data['name']}');
    return data;
  }
}
