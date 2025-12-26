import 'package:sambura_core/application/ports/auth_port.dart';
import 'package:sambura_core/application/ports/cache_port.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:sambura_core/infrastructure/api/controller/auth/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/system/system_controller.dart';
import 'package:sambura_core/infrastructure/api/middleware/auth_middleware.dart';
import 'package:sambura_core/infrastructure/api/middleware/require_auth_middlware.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class MainRouter {
  final AuthController _authController;
  final SystemController _systemController;
  final AuthPort _authProvider;
  final AccountRepository _accountRepo;
  final ApiKeyRepository _keyRepo;

  // Redis for cache
  final CachePort _cachePort;

  MainRouter(
    this._authController,
    this._systemController,
    this._authProvider,
    this._accountRepo,
    this._keyRepo,
    this._cachePort,
  );

  Handler get handler {
    final baseRouter = Router();

    // --- 1. Sub-roteador para recursos que requerem autenticação obrigatória ---
    final protectedRouter = Router();
    protectedRouter.post('/auth/register', _authController.register);
    // Adicione outras rotas privadas aqui

    // --- 2. Sub-roteador para recursos públicos ---
    final publicRouter = Router();
    publicRouter.mount('/system', _systemController.router.call);
    publicRouter.post('/auth/login', _authController.login);

    // --- 3. Composição dos Middlewares ---

    // Resolve a identidade para todas as rotas (JWT ou ApiKey)
    final resolveIdentity = authMiddleware(
      _accountRepo,
      _keyRepo,
      _authProvider,
      _cachePort,
    );

    // Protege o acesso (Retorna 401 se não houver usuário no context)
    final requireAuth = RequireAuthMiddleware.check();

    // Montagem final sob o prefixo /api/v1
    baseRouter.mount(
      '/api/v1',
      Pipeline().addMiddleware(resolveIdentity).addHandler(publicRouter.call),
    );

    baseRouter.mount(
      '/api/v1',
      Pipeline()
          .addMiddleware(resolveIdentity)
          .addMiddleware(requireAuth)
          .addHandler(protectedRouter.call),
    );

    return baseRouter.call;
  }
}
