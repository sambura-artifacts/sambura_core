import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:sambura_core/infrastructure/services/hash_service.dart';
import 'package:sambura_core/utils/crypto_utils.dart';

class ApiKeyResponse {
  final String plainKey;
  final String name;

  ApiKeyResponse(this.plainKey, this.name);
}

class GenerateApiKeyUsecase {
  final ApiKeyRepository _keyRepo;
  final HashService _hashService;

  GenerateApiKeyUsecase(this._keyRepo, this._hashService);

  Future<ApiKeyResponse> execute({
    required int accountId,
    required String keyName,
  }) async {
    final prefix = 'sb_';
    final securePart = CryptoUtils.generateSecureKey(32);
    final plainKey = '$prefix$securePart';

    final hashedKey = _hashService.hashPassword(plainKey);

    await _keyRepo.create(
      accountId: accountId,
      name: keyName,
      keyHash: hashedKey,
      prefix: prefix,
    );

    return ApiKeyResponse(plainKey, keyName);
  }
}
