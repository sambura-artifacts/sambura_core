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
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';

class MainRouter {
  final AuthController _authController;
  final SystemController _systemController;
  final AuthPort _authProvider;
  final AccountRepository _accountRepo;
  final ApiKeyRepository _keyRepo;

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
    final apiRouter = Router();

    final swaggerHandler = SwaggerUI(
      'specs/swagger.yaml',
      title: 'Samburá Docs',
    );
    apiRouter.all('/docs/<any|.*>', swaggerHandler.call);

    // Rotas da API v1
    final v1Router = Router();

    // --- Sub-roteador Público ---
    final publicActions = Router();
    publicActions.mount('/system', _systemController.router.call);
    publicActions.post('/auth/login', _authController.login);

    // --- Sub-roteador Protegido ---
    final protectedActions = Router();
    protectedActions.post('/auth/register', _authController.register);
    // Adicione mais aqui...

    // Montagem do v1 com os respectivos Middlewares
    v1Router.mount('/', publicActions.call);

    v1Router.mount(
      '/',
      Pipeline()
          .addMiddleware(RequireAuthMiddleware.check())
          .addHandler(protectedActions.call),
    );

    // Pipeline Principal da API
    final apiPipeline = Pipeline()
        .addMiddleware(
          authMiddleware(_accountRepo, _keyRepo, _authProvider, _cachePort),
        )
        .addHandler(v1Router.call);

    apiRouter.mount('/api/v1', apiPipeline);

    return apiRouter.call;
  }
}
