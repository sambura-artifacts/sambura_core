import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';

class GenerateApiKeyResult {
  final String name;
  final String plainKey;
  final String prefix;

  GenerateApiKeyResult(this.name, this.plainKey, this.prefix);
}

class GenerateApiKeyUsecase {
  final ApiKeyRepository _repository;
  final Logger _log = LoggerConfig.getLogger('GenerateApiKeyUsecase');

  GenerateApiKeyUsecase(this._repository);

  Future<GenerateApiKeyResult> execute({
    required int accountId,
    required String keyName,
  }) async {
    _log.info('Gerando nova API key: accountId=$accountId, name=$keyName');

    try {
      _log.fine('Gerando chave aleatória segura');
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));

      final plainKey =
          'sb_live_${base64Url.encode(values).replaceAll('=', '')}';

      _log.fine('Gerando hash da chave');
      final hash = sha256.convert(utf8.encode(plainKey)).toString();

      _log.fine('Salvando API key no repositório');
      await _repository.create(
        accountId: accountId,
        name: keyName,
        keyHash: hash,
        prefix: 'sb_live_',
      );

      _log.info('✓ API key gerada com sucesso: name=$keyName, prefix=sb_live_');
      return GenerateApiKeyResult(keyName, plainKey, 'sb_live_');
    } catch (e, stack) {
      _log.severe(
        '✗ Erro ao gerar API key para accountId=$accountId',
        e,
        stack,
      );
      rethrow;
    }
  }
}
