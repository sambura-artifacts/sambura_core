import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';

class VaultService {
  final String endpoint;
  final String token;
  final Logger _log = LoggerConfig.getLogger('VaultService');

  VaultService(this.endpoint, this.token);

  Future<Map<String, dynamic>> getSecrets(String path) async {
    try {
      var cleanPath = path;
      if (cleanPath.startsWith('secret/data/')) {
        cleanPath = cleanPath.replaceFirst('secret/data/', '');
      }
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }

      _log.info('🔐 Consultando Vault: $endpoint/v1/secret/data/$cleanPath');

      final url = Uri.parse('$endpoint/v1/secret/data/$cleanPath');

      final response = await http
          .get(
            url,
            headers: {
              'X-Vault-Token': token,
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 5),
          ); // Timeout para não travar o boot
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // O Vault KV-V2 sempre encapsula em data -> data

        return body['data']['data'] as Map<String, dynamic>;
      } else {
        _log.severe('❌ Vault erro ${response.statusCode}: ${response.body}');
        return {};
      }
    } catch (e) {
      _log.severe('🔥 Falha crítica na comunicação com o Vault: $e');
      _log.severe(
        '💡 Dica: Verifique se o VAULT_ADDR no .env está como http://localhost:8200',
      );
      return {};
    }
  }

  /// Grava ou atualiza segredos no Vault (KV-V2).
  /// O payload é automaticamente encapsulado no campo 'data' exigido pelo Vault.
  Future<bool> write(String path, Map<String, dynamic> data) async {
    try {
      // 1. Limpeza de Path (Consistência com getSecrets)
      var cleanPath = path;
      if (cleanPath.startsWith('secret/data/')) {
        cleanPath = cleanPath.replaceFirst('secret/data/', '');
      }
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }

      final url = Uri.parse('$endpoint/v1/secret/data/$cleanPath');
      _log.info('🔐 Gravando no Vault: $url');

      // 2. O Vault KV-V2 exige que os dados estejam dentro da chave "data"
      final payload = jsonEncode({'data': data});

      final response = await http
          .post(
            url,
            headers: {
              'X-Vault-Token': token,
              'Content-Type': 'application/json',
            },
            body: payload,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 204) {
        _log.info('✅ Segredo gravado com sucesso no path: $cleanPath');
        return true;
      } else {
        _log.severe(
          '❌ Erro ao gravar no Vault (${response.statusCode}): ${response.body}',
        );
        return false;
      }
    } catch (e) {
      _log.severe('🔥 Falha ao comunicar com o Vault durante escrita: $e');
      return false;
    }
  }
}
