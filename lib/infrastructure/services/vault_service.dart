import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';

class VaultService {
  final String endpoint;
  final String token;
  final Logger _log = LoggerConfig.getLogger('VaultService');

  VaultService({required this.endpoint, required this.token});

  Future<Map<String, dynamic>> getSecrets(String path) async {
    try {
      _log.info('🔐 Consultando Vault no caminho: $path');

      // No Vault KV-V2, a URL é: v1/secret/data/[path]
      final url = Uri.parse('$endpoint/v1/secret/data/$path');

      final response = await http.get(
        url,
        headers: {'X-Vault-Token': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // O Vault encapsula os dados em data -> data
        return body['data']['data'] as Map<String, dynamic>;
      } else {
        _log.severe(
          '❌ Vault respondeu com erro: ${response.statusCode} - ${response.body}',
        );
        return {};
      }
    } catch (e) {
      _log.severe('🔥 Falha na comunicação com o Vault: $e');
      return {};
    }
  }
}
