import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/application/ports/auth_port.dart';
import 'package:sambura_core/application/ports/cache_port.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:sambura_core/infrastructure/mappers/account_mapper.dart';
import 'package:shelf/shelf.dart';

final _log = Logger('AuthMiddleware');

Middleware authMiddleware(
  AccountRepository accountRepo,
  ApiKeyRepository keyRepo,
  AuthPort authProvider,
  CachePort cache,
) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return innerHandler(request);
      }

      final token = authHeader.substring(7);

      // --- 1. Fluxo de API KEY (sb_...) ---
      if (token.startsWith('sb_')) {
        try {
          final hash = sha256.convert(utf8.encode(token)).toString();
          final cacheKey = 'auth:apikey:$hash';

          // Tentativa no Cache
          final cachedUser = await cache.get(cacheKey);
          if (cachedUser != null) {
            final account = AccountMapper.fromMap(jsonDecode(cachedUser));
            return innerHandler(request.change(context: {'user': account}));
          }

          // DB fallback
          final apiKeyData = await keyRepo.findByHash(hash);
          if (apiKeyData == null || apiKeyData.isExpired) {
            return Response(
              401,
              body: '{"error": "ApiKey inválida ou expirada"}',
              headers: {'content-type': 'application/json'},
            );
          }

          final account = await accountRepo.findById(apiKeyData.accountId);
          if (account != null) {
            await cache.set(
              cacheKey,
              jsonEncode(AccountMapper.toMap(account)),
              ttl: Duration(minutes: 5),
            );

            // Atualização assíncrona (Fire and Forget)
            keyRepo.updateLastUsed(apiKeyData.id!);

            return innerHandler(request.change(context: {'user': account}));
          }
        } catch (e) {
          _log.severe('Erro na validação de ApiKey', e);
          return Response.internalServerError();
        }
      }

      // --- 2. Fluxo de JWT (User Session) ---
      try {
        final payload = authProvider.verifyToken(token);
        if (payload != null) {
          final String externalId = payload['sub'];
          final cacheKey = 'auth:session:$externalId';

          final cachedUser = await cache.get(cacheKey);
          if (cachedUser != null) {
            final account = AccountMapper.fromMap(jsonDecode(cachedUser));
            return innerHandler(request.change(context: {'user': account}));
          }

          final account = await accountRepo.findByExternalId(externalId);
          if (account != null) {
            await cache.set(
              cacheKey,
              jsonEncode(AccountMapper.toMap(account)),
              ttl: const Duration(minutes: 15),
            );

            return innerHandler(request.change(context: {'user': account}));
          }
        }
      } catch (_) {
        _log.info('JWT inválido ignorado.');
      }

      return innerHandler(request);
    };
  };
}
