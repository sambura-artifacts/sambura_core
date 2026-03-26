import 'package:sambura_core/config/env.dart';
import 'package:sambura_core/infrastructure/api/presenter/error_presenter.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:sambura_core/infrastructure/api/middleware/auth_middleware.dart';
import 'package:sambura_core/infrastructure/api/middleware/require_auth_middlware.dart';
import 'package:sambura_core/infrastructure/api/routes/public_router.dart';
import 'package:sambura_core/infrastructure/api/routes/protected_router.dart';
import 'package:sambura_core/infrastructure/api/middleware/error_handler_middleware.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';

class MainRouter {
  final EnvConfig _config;
  final PublicRouter _publicRouter;
  final ProtectedRouter _protectedRouter;
  final AccountRepository _accountRepo;
  final ApiKeyRepository _keyRepo;
  final AuthPort _authProvider;
  final CachePort _cache;
  final MetricsPort _metricsPort;

  MainRouter(
    this._config,
    this._publicRouter,
    this._protectedRouter,
    this._accountRepo,
    this._keyRepo,
    this._authProvider,
    this._cache,
    this._metricsPort,
  );

  Handler get handler {
    final router = Router(
      notFoundHandler: (Request request) {
        return ErrorPresenter.notFoundRoute(
          request.requestedUri.path,
          _config.publicOrigin,
        );
      },
    );

    final apiPipeline = Pipeline()
        .addMiddleware(errorHandler(_config.publicOrigin, _metricsPort))
        .addMiddleware(
          authMiddleware(
            _accountRepo,
            _keyRepo,
            _authProvider,
            _cache,
            _metricsPort,
          ),
        )
        .addHandler(_buildApiRoutes().call);

    router.mount('/api/v1', apiPipeline);

    return router.call;
  }

  Router _buildApiRoutes() {
    final v1 = Router(
      notFoundHandler: (Request request) {
        return ErrorPresenter.notFoundRoute(
          request.requestedUri.path,
          _config.publicOrigin,
        );
      },
    );

    // --- Rotas Públicas ---
    // (Ex: Login, Docs, Health, Proxy de Leitura)
    v1.mount('/', _publicRouter.router.call);

    // --- Rotas Protegidas ---
    // (Ex: Register, Admin, Upload, Management)
    // Monta apenas rotas específicas do protected router que não conflitam
    v1.mount(
      '/',
      Pipeline()
          .addMiddleware(errorHandler(_config.publicOrigin, _metricsPort))
          .addMiddleware(RequireAuthMiddleware.check())
          .addHandler(_protectedRouter.router.call),
    );

    return v1;
  }
}
