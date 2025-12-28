import 'package:sambura_core/config/env.dart';
import 'package:sambura_core/infrastructure/api/controller/system/metrics_controller.dart';
import 'package:sambura_core/infrastructure/api/middleware/error_handler_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';
import 'package:sambura_core/infrastructure/api/controller/auth/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/system/system_controller.dart';
import 'package:sambura_core/infrastructure/api/middleware/auth_middleware.dart';
import 'package:sambura_core/application/shared/ports/ports.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';

class PublicRouter {
  final EnvConfig _config;
  final AuthController _authController;
  final ArtifactController _artifactController;
  final BlobController _blobController;
  final SystemController _systemController;
  final MetricsController _metricsController;
  final ApiKeyRepository _apiKeyRepo;
  final AccountRepository _accountRepo;
  final AuthPort _authProvider;
  final CachePort _cache;
  final MetricsPort _metricsPort;

  PublicRouter(
    this._config,
    this._authController,
    this._artifactController,
    this._blobController,
    this._systemController,
    this._metricsController,
    this._apiKeyRepo,
    this._accountRepo,
    this._authProvider,
    this._cache,
    this._metricsPort,
  );

  Router get router {
    final router = Router();

    // 1. Swagger e Métricas (Abertos)
    final swaggerHandler = SwaggerUI(
      'specs/swagger.yaml',
      title: 'Samburá Docs',
    );
    router.all('/docs/<any|.*>', swaggerHandler.call);
    router.get('/metrics', _metricsController.getMetrics);

    // 2. System Router (Health Check)
    router.mount('/system', _systemController.router.call);

    // 3. Auth Routes
    router.post('/auth/register', _authController.register);
    router.post('/auth/login', _authController.login);

    // 4. NPM Proxy Routes
    router.get(
      '/npm/<repo>/<package|.*>/-/<filename>',
      _artifactController.downloadTarball,
    );
    router.get(
      '/npm/<repo>/<packageName|.*>',
      _artifactController.getPackageMetadata,
    );

    // 5. Pipeline Protegida com Métricas
    final secureResolverPipeline = Pipeline()
        .addMiddleware(
          errorHandler(_config.publicOrigin, _metricsPort),
        ) // Se o seu errorHandler usar métricas, passe-as aqui também
        .addMiddleware(
          authMiddleware(
            _accountRepo,
            _apiKeyRepo,
            _authProvider,
            _cache,
            _metricsPort, // INJETADO AQUI
          ),
        )
        .addHandler((Request request) async {
          final inner = Router();
          inner.get(
            '/download/<namespace>/<name>/<version>',
            _artifactController.downloadByVersion,
          );
          inner.get('/blobs/<hash>', _blobController.download);
          inner.get(
            '/<repositoryName>/<packageName>/<version>',
            _artifactController.resolve,
          );
          return inner.call(request);
        });

    router.mount('/', secureResolverPipeline);

    return router;
  }
}
