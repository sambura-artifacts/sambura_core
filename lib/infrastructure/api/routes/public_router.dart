import 'package:sambura_core/application/ports/auth_port.dart';
import 'package:sambura_core/application/ports/cache_port.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';
import 'package:sambura_core/infrastructure/api/controller/auth/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/middleware/auth_middleware.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';

class PublicRouter {
  final AuthController _authController;
  final ArtifactController _artifactController;
  final BlobController _blobController;
  final ApiKeyRepository _apiKeyRepo;
  final AccountRepository _accountRepo;
  final AuthPort _authProvider;
  final CachePort _cache;

  PublicRouter(
    this._authController,
    this._artifactController,
    this._blobController,
    this._apiKeyRepo,
    this._accountRepo,
    this._authProvider,
    this._cache,
  );

  Router get router {
    final router = Router();

    final swaggerHandler = SwaggerUI(
      'specs/swagger.yaml',
      title: 'Samburá Docs',
    );
    router.all('/docs/<any|.*>', swaggerHandler.call);

    router.post('/auth/register', _authController.register);
    router.post('/auth/login', _authController.login);

    // Rota do NPM com Catch-all para Scopes (@scope/package)
    router.get(
      '/npm/<repo>/<packageName|.*>',
      _artifactController.getPackageMetadata,
    );

    final secureResolverPipeline = Pipeline()
        .addMiddleware(
          authMiddleware(_accountRepo, _apiKeyRepo, _authProvider, _cache),
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
