import 'package:logging/logging.dart';
import 'package:sambura_core/application/exceptions/application_exception.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';

class RevokeApiKeyUsecase {
  final ApiKeyRepository _apiKeyRepository;
  final AccountRepository _accountRepository;
  final Logger _log = LoggerConfig.getLogger('RevokeApiKeyUsecase');

  RevokeApiKeyUsecase(this._apiKeyRepository, this._accountRepository);

  Future<void> execute({
    required String key,
    required String requestUserId,
  }) async {
    _log.info('Tentativa de revogação: keyId=$key por userId=$requestUserId');

    final apiKey = await _apiKeyRepository.findByHash(key);

    print("API KEY ${apiKey?.accountId} == $key");

    if (apiKey == null) {
      throw ApiKeyNotFoundException(key);
    }

    final user = await _accountRepository.findByExternalId(requestUserId);

    if (user == null) {
      throw AccountNotFoundException(requestUserId);
    }

    final isOwner = apiKey.accountId == user.id;

    if (!isOwner && !user.isAdmin) {
      _log.warning(
        '⚠️ Acesso negado: Usuário $requestUserId tentou revogar chave de outro usuário.',
      );
      throw AccountNotPermissionException(
        'Você não tem permissão para revogar esta chave.',
      );
    }

    try {
      await _apiKeyRepository.delete(apiKey.id!);
      _log.info('✓ API key $key revogada com sucesso por $requestUserId');
    } catch (e, stack) {
      _log.severe('Erro ao revogar API key: keyId=${apiKey.id!}', e, stack);
      rethrow;
    }
  }
}
