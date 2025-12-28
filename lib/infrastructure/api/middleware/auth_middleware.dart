import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

import 'package:shelf/shelf.dart';

// Ports

// Adapters & Mappers
import 'package:sambura_core/infrastructure/mappers/account_mapper.dart';
import 'package:sambura_core/application/auth/ports/ports.dart';
import 'package:sambura_core/application/shared/ports/ports.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';

final _log = Logger('AuthMiddleware');

Middleware authMiddleware(
  AccountRepository accountRepo,
  ApiKeyRepository keyRepo,
  AuthPort authProvider,
  CachePort cache,
  MetricsPort metrics,
) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return innerHandler(request);
      }

      final token = authHeader.substring(7);

      // --- 1. FLUXO DE API KEY (sb_...) ---
      if (token.startsWith('sb_')) {
        try {
          final hash = sha256.convert(utf8.encode(token)).toString();
          final cacheKey = 'auth:apikey:$hash';

          final cachedUser = await cache.get(cacheKey);
          if (cachedUser != null) {
            // MÉTRICA: Cache Hit
            metrics.recordAuthCache('hit', 'apikey');

            final account = AccountMapper.fromMap(jsonDecode(cachedUser));
            return innerHandler(request.change(context: {'user': account}));
          }

          final apiKeyData = await keyRepo.findByHash(hash);
          if (apiKeyData == null || apiKeyData.isExpired) {
            // MÉTRICA: Segurança
            metrics.recordAuthFailure('invalid_apikey');

            return Response(
              401,
              body: jsonEncode({'error': 'ApiKey inválida ou expirada'}),
              headers: {'content-type': 'application/json'},
            );
          }

          final account = await accountRepo.findById(apiKeyData.accountId);
          if (account != null) {
            // MÉTRICA: Cache Miss
            metrics.recordAuthCache('miss', 'apikey');

            await cache.set(
              cacheKey,
              jsonEncode(AccountMapper.toMap(account)),
              ttl: const Duration(minutes: 5),
            );

            keyRepo.updateLastUsed(apiKeyData.id!);
            return innerHandler(request.change(context: {'user': account}));
          }
        } catch (e, stack) {
          _log.severe('Erro na validação de ApiKey', e, stack);
          return Response.internalServerError();
        }
      }

      // --- 2. FLUXO DE JWT (User Session) ---
      try {
        final payload = authProvider.verifyToken(token);

        if (payload == null) {
          metrics.recordAuthFailure('invalid_jwt');
          return innerHandler(request);
        }

        final String externalId = payload['sub'];
        final cacheKey = 'auth:session:$externalId';

        final cachedUser = await cache.get(cacheKey);
        if (cachedUser != null) {
          // MÉTRICA: Cache Hit
          metrics.recordAuthCache('hit', 'jwt');

          final account = AccountMapper.fromMap(jsonDecode(cachedUser));
          return innerHandler(request.change(context: {'user': account}));
        }

        final account = await accountRepo.findByExternalId(externalId);
        if (account != null) {
          // MÉTRICA: Cache Miss
          metrics.recordAuthCache('miss', 'jwt');

          await cache.set(
            cacheKey,
            jsonEncode(AccountMapper.toMap(account)),
            ttl: const Duration(minutes: 15),
          );

          return innerHandler(request.change(context: {'user': account}));
        }
      } catch (e, stack) {
        _log.severe('Erro crítico no processamento de JWT', e, stack);
        metrics.recordViolation('jwt_processing_error');
      }

      return innerHandler(request);
    };
  };
}
