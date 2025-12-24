import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:sambura_core/infrastructure/services/auth/auth_service.dart';
import 'package:sambura_core/infrastructure/services/auth/hash_service.dart';
import 'package:shelf/shelf.dart';

final _log = Logger('AuthMiddleware');

Middleware authMiddleware(
  AccountRepository accountRepo,
  AuthService authService,
  ApiKeyRepository keyRepo,
  HashService hashService,
) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return innerHandler(request);
      }

      final token = authHeader.substring(7);

      if (token.startsWith('sb_')) {
        try {
          final hash = sha256.convert(utf8.encode(token)).toString();
          _log.info("Hash $hash");

          final apiKeyData = await keyRepo.findByHash(hash);
          _log.info("apiKeyData $apiKeyData");

          if (apiKeyData == null) {
            _log.warning('⚠️ ApiKey inválida ou não encontrada no banco.');
            return Response(
              401,
              body: '{"error": "ApiKey inválida"}',
              headers: {'content-type': 'application/json'},
            );
          }

          final isExpired =
              apiKeyData.expiresAt != null &&
              apiKeyData.expiresAt!.isBefore(DateTime.now());

          if (isExpired) {
            _log.warning('⚠️ ApiKey expirada: ${apiKeyData.name}');
            return Response(
              401,
              body: '{"error": "ApiKey expirada"}',
              headers: {'content-type': 'application/json'},
            );
          }

          final account = await accountRepo.findById(apiKeyData.accountId);
          if (account == null) {
            _log.severe(
              '🔥 ApiKey válida mas conta vinculada (ID: ${apiKeyData.accountId}) sumiu!',
            );
            return Response(
              401,
              body: '{"error": "Conta inválida"}',
              headers: {'content-type': 'application/json'},
            );
          }

          _log.fine('✅ Acesso via ApiKey concedido: ${account.username}');
          keyRepo.updateLastUsed(apiKeyData.id!);

          final updatedRequest = request.change(context: {'user': account});
          return innerHandler(updatedRequest);
        } catch (e, stack) {
          _log.severe('💥 Erro ao validar ApiKey', e, stack);
          return Response.internalServerError(
            body: 'Erro interno na validação da chave',
          );
        }
      }

      try {
        final userId = authService.verifyToken(token);
        if (userId != null) {
          final account = await accountRepo.findById(int.parse(userId));
          if (account != null) {
            _log.fine('✅ Acesso via JWT concedido: ${account.username}');
            final updatedRequest = request.change(context: {'user': account});
            return innerHandler(updatedRequest);
          }
        }
      } catch (e) {
        _log.info('Token JWT inválido ou mal formatado ignorado.');
      }

      return innerHandler(request);
    };
  };
}
