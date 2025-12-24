import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:sambura_core/infrastructure/services/auth/hash_service.dart';
import 'package:sambura_core/shared/utils/crypto_utils.dart';

/// O que o cria recebe de volta (A chave só aparece aqui!)
class ApiKeyCreated {
  final String plainKey;
  final String name;

  ApiKeyCreated(this.plainKey, this.name);
}

class CreateApiKeyUsecase {
  final ApiKeyRepository _keyRepo;
  final HashService _hashService;
  final Logger _log = LoggerConfig.getLogger('CreateApiKeyUsecase');

  CreateApiKeyUsecase(this._keyRepo, this._hashService);

  Future<ApiKeyCreated> execute({
    required int accountId,
    required String keyName,
  }) async {
    _log.info('Criando nova API key: accountId=$accountId, name=$keyName');

    try {
      final prefix = 'sb_live_';

      _log.fine('Gerando parte segura da chave');
      final securePart = CryptoUtils.generateSecureKey(32);
      final plainKey = '$prefix$securePart';

      _log.fine('Gerando hash da chave');
      final keyHash = _hashService.hashPassword(plainKey);

      _log.fine('Salvando API key no repositório');
      await _keyRepo.create(
        accountId: accountId,
        name: keyName,
        keyHash: keyHash,
        prefix: prefix,
      );

      _log.info('✓ API key criada com sucesso: name=$keyName, prefix=$prefix');
      return ApiKeyCreated(plainKey, keyName);
    } catch (e, stack) {
      _log.severe(
        '✗ Erro ao criar API key para accountId=$accountId',
        e,
        stack,
      );
      rethrow;
    }
  }
}
