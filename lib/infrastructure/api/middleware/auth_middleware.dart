import 'package:sambura_core/domain/repositories/account_repository.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:sambura_core/infrastructure/services/auth_service.dart';
import 'package:sambura_core/infrastructure/services/hash_service.dart';
import 'package:shelf/shelf.dart';

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
        final hash = hashService.hashPassword(token);
        final apiKeyData = await keyRepo.findByHash(hash);

        if (apiKeyData != null) {
          final account = await accountRepo.findById(apiKeyData.accountId);
          if (account != null) {
            final updatedRequest = request.change(context: {'user': account});
            return innerHandler(updatedRequest);
          }
        }
      }

      final userId = authService.verifyToken(token);
      if (userId != null) {
        final account = await accountRepo.findById(int.parse(userId));

        if (account != null) {
          final updatedRequest = request.change(context: {'user': account});
          return innerHandler(updatedRequest);
        }
      }

      return innerHandler(request);
    };
  };
}
