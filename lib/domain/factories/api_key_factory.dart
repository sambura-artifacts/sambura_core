import 'package:sambura_core/domain/entities/api_key_entity.dart';
import 'package:sambura_core/domain/value_objects/api_key_value.dart';
import 'package:sambura_core/application/ports/hash_port.dart';

/// Factory para criação de ApiKeyEntity.
/// 
/// Encapsula a lógica de geração e validação de API Keys.
class ApiKeyFactory {
  final IHashPort _hashPort;

  ApiKeyFactory(this._hashPort);

  /// Gera uma nova API Key segura.
  /// 
  /// [accountId] - ID da conta proprietária
  /// [name] - Nome descritivo da chave
  /// [environment] - Ambiente ('live' ou 'test')
  Future<({ApiKeyEntity entity, String plainKey})> generate({
    required int accountId,
    required String name,
    String environment = 'live',
  }) async {
    // Validações
    if (accountId <= 0) {
      throw ArgumentError('Invalid account ID');
    }

    if (name.isEmpty) {
      throw ArgumentError('Key name cannot be empty');
    }

    if (environment != 'live' && environment != 'test') {
      throw ArgumentError('Environment must be live or test');
    }

    // Gera a chave aleatória
    final randomPart = _hashPort.generateRandomString(32);
    final plainKey = 'sb_${environment}_$randomPart';

    // Cria o Value Object
    final apiKeyValue = ApiKeyValue.create(plainKey);

    // Hasheia a chave para armazenamento
    final keyHash = _hashPort.sha256Hash(plainKey.codeUnits);

    // Cria a entidade
    final entity = ApiKeyEntity(
      accountId: accountId,
      name: name,
      keyHash: keyHash,
      prefix: apiKeyValue.prefix,
      createdAt: DateTime.now().toUtc(),
    );

    return (entity: entity, plainKey: plainKey);
  }

  /// Reconstrói uma API Key a partir dos dados do banco.
  static ApiKeyEntity fromDatabase(Map<String, dynamic> row) {
    return ApiKeyEntity(
      id: row['id'] as int?,
      accountId: row['account_id'] as int,
      name: row['name'] as String,
      keyHash: row['key_hash'] as String,
      prefix: row['prefix'] as String,
      createdAt: row['created_at'] is DateTime
          ? row['created_at'] as DateTime
          : DateTime.parse(row['created_at'] as String),
      lastUsedAt: row['last_used_at'] != null
          ? (row['last_used_at'] is DateTime
              ? row['last_used_at'] as DateTime
              : DateTime.parse(row['last_used_at'] as String))
          : null,
      expiresAt: row['expires_at'] != null
          ? (row['expires_at'] is DateTime
              ? row['expires_at'] as DateTime
              : DateTime.parse(row['expires_at'] as String))
          : null,
    );
  }

  /// Verifica se uma chave plain corresponde ao hash.
  bool verifyKey(String plainKey, String storedHash) {
    final computedHash = _hashPort.sha256Hash(plainKey.codeUnits);
    return computedHash == storedHash;
  }

  /// Marca a chave como usada (atualiza last_used_at).
  static ApiKeyEntity markAsUsed(ApiKeyEntity key) {
    return ApiKeyEntity(
      id: key.id,
      accountId: key.accountId,
      name: key.name,
      keyHash: key.keyHash,
      prefix: key.prefix,
      createdAt: key.createdAt,
      lastUsedAt: DateTime.now().toUtc(),
      expiresAt: key.expiresAt,
    );
  }
}
