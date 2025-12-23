import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:sambura_core/infrastructure/services/hash_service.dart';

class GenerateApiKeyResult {
  final String name;
  final String plainKey;

  GenerateApiKeyResult(this.name, this.plainKey);
}

class GenerateApiKeyUsecase {
  final ApiKeyRepository _repository;

  GenerateApiKeyUsecase(this._repository);

  Future<GenerateApiKeyResult> execute({
    required int accountId,
    required String keyName,
  }) async {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));

    final plainKey = 'sb_live_${base64Url.encode(values).replaceAll('=', '')}';

    final hash = sha256.convert(utf8.encode(plainKey)).toString();

    await _repository.create(
      accountId: accountId,
      name: keyName,
      keyHash: hash,
      prefix: 'sb_live_',
    );

    return GenerateApiKeyResult(keyName, plainKey);
  }
}
