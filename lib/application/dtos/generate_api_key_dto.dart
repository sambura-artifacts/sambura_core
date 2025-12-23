import 'package:sambura_core/domain/value_objects/api_key_value.dart';

/// DTO de entrada para gerar API Key.
class GenerateApiKeyInput {
  final int accountId;
  final String keyName;
  final String environment; // 'live' ou 'test'

  const GenerateApiKeyInput({
    required this.accountId,
    required this.keyName,
    this.environment = 'live',
  });

  bool get isValid {
    return accountId > 0 &&
        keyName.isNotEmpty &&
        (environment == 'live' || environment == 'test');
  }

  String get prefix => 'sb_${environment}_';
}

/// DTO de saída para gerar API Key.
class GenerateApiKeyOutput {
  final int keyId;
  final String keyName;
  final ApiKeyValue
  apiKey; // Contém a chave completa (só é retornada na criação)
  final DateTime createdAt;

  const GenerateApiKeyOutput({
    required this.keyId,
    required this.keyName,
    required this.apiKey,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'key_id': keyId,
    'name': keyName,
    'api_key': apiKey.plainValue, // Atenção: só expor na criação!
    'prefix': apiKey.prefix,
    'is_live': apiKey.isLive,
    'created_at': createdAt.toIso8601String(),
  };

  /// Versão segura sem a chave completa (para listagens)
  Map<String, dynamic> toSafeJson() => {
    'key_id': keyId,
    'name': keyName,
    'prefix': apiKey.prefix,
    'masked': apiKey.masked,
    'is_live': apiKey.isLive,
    'created_at': createdAt.toIso8601String(),
  };
}
