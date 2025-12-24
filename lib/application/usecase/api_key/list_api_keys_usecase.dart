import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/entities/api_key_entity.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';

class ListApiKeysUsecase {
  final ApiKeyRepository _repository;
  final Logger _log = LoggerConfig.getLogger('ListApiKeysUsecase');

  ListApiKeysUsecase(this._repository);

  Future<List<ApiKeyEntity>> execute({required int accountId}) async {
    _log.info('Listando API keys: accountId=$accountId');

    try {
      final keys = await _repository.findAllByAccountId(accountId);

      _log.info(
        '✓ Encontradas ${keys.length} API keys para accountId=$accountId',
      );

      return keys;
    } catch (e, stack) {
      _log.severe('Erro ao listar API keys: accountId=$accountId', e, stack);
      rethrow;
    }
  }
}
