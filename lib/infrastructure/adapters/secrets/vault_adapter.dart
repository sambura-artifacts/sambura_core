import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/ports/secret_port.dart';

/// Adapter para HashiCorp Vault implementando SecretPort.
///
/// Segue o padrão Hexagonal Architecture (Ports & Adapters).
class VaultAdapter implements SecretPort {
  final String _endpoint;
  final String _token;
  final Logger _log = LoggerConfig.getLogger('VaultAdapter');

  VaultAdapter({required String endpoint, required String token})
    : _endpoint = endpoint,
      _token = token;

  @override
  Future<Map<String, dynamic>> getSecrets(String path) async {
    try {
      final cleanPath = _sanitizePath(path);

      _log.fine('🔐 Fetching secrets from Vault: $cleanPath');

      final url = Uri.parse('$_endpoint/v1/secret/data/$cleanPath');

      final response = await http
          .get(
            url,
            headers: {
              'X-Vault-Token': _token,
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final secrets = body['data']['data'] as Map<String, dynamic>;
        _log.fine('✅ Secrets retrieved successfully');
        return secrets;
      } else if (response.statusCode == 404) {
        _log.warning('⚠️  Secrets not found at path: $cleanPath');
        return {};
      } else {
        _log.severe('❌ Vault error ${response.statusCode}: ${response.body}');
        return {};
      }
    } catch (e, stack) {
      _log.severe('🔥 Failed to communicate with Vault: $e', e, stack);
      return {};
    }
  }

  @override
  Future<String?> getSecret(String path, String key) async {
    final secrets = await getSecrets(path);
    return secrets[key]?.toString();
  }

  @override
  Future<void> putSecrets(String path, Map<String, dynamic> secrets) async {
    try {
      final cleanPath = _sanitizePath(path);

      _log.info('📝 Storing secrets to Vault: $cleanPath');

      final url = Uri.parse('$_endpoint/v1/secret/data/$cleanPath');

      final response = await http
          .post(
            url,
            headers: {
              'X-Vault-Token': _token,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'data': secrets}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 204) {
        _log.info('✅ Secrets stored successfully');
      } else {
        _log.severe('❌ Failed to store secrets: ${response.statusCode}');
        throw Exception('Failed to store secrets in Vault');
      }
    } catch (e, stack) {
      _log.severe('🔥 Failed to store secrets: $e', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> deleteSecret(String path) async {
    try {
      final cleanPath = _sanitizePath(path);

      _log.warning('🗑️  Deleting secrets from Vault: $cleanPath');

      final url = Uri.parse('$_endpoint/v1/secret/data/$cleanPath');

      final response = await http
          .delete(url, headers: {'X-Vault-Token': _token})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 204) {
        _log.info('✅ Secrets deleted successfully');
      } else {
        _log.warning('⚠️  Failed to delete secrets: ${response.statusCode}');
      }
    } catch (e, stack) {
      _log.severe('🔥 Failed to delete secrets: $e', e, stack);
      rethrow;
    }
  }

  @override
  Future<bool> exists(String path) async {
    final secrets = await getSecrets(path);
    return secrets.isNotEmpty;
  }

  /// Remove prefixos redundantes do path.
  String _sanitizePath(String path) {
    var cleaned = path;

    // Remove prefix "secret/data/" se presente
    if (cleaned.startsWith('secret/data/')) {
      cleaned = cleaned.replaceFirst('secret/data/', '');
    }

    // Remove leading slash
    if (cleaned.startsWith('/')) {
      cleaned = cleaned.substring(1);
    }

    return cleaned;
  }
}
