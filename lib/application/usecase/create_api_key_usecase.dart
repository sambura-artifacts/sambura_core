import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:sambura_core/infrastructure/services/hash_service.dart';
import 'package:sambura_core/utils/crypto_utils.dart';

/// O que o cria recebe de volta (A chave só aparece aqui!)
class ApiKeyCreated {
  final String plainKey;
  final String name;

  ApiKeyCreated(this.plainKey, this.name);
}

class CreateApiKeyUsecase {
  final ApiKeyRepository _keyRepo;
  final HashService _hashService;

  CreateApiKeyUsecase(this._keyRepo, this._hashService);

  Future<ApiKeyCreated> execute({
    required int accountId,
    required String keyName,
  }) async {
    final prefix = 'sb_live_';
    final securePart = CryptoUtils.generateSecureKey(32);
    final plainKey = '$prefix$securePart';

    final keyHash = _hashService.hashPassword(plainKey);

    await _keyRepo.create(
      accountId: accountId,
      name: keyName,
      keyHash: keyHash,
      prefix: prefix,
    );

    return ApiKeyCreated(plainKey, keyName);
  }
}
