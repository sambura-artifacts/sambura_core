import 'dart:io';
import 'package:sambura_core/config/env.dart';
import 'package:sambura_core/infrastructure/api/routes/package_manager_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/infrastructure/api/controller/auth/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/system/system_controller.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';

class PublicRouter {
  final EnvConfig _config;
  final PackageManagerRouter _packageManagerRouter;
  final AuthController _authController;
  final ArtifactController _artifactController;
  final BlobController _blobController;
  final SystemController _systemController;
  final ApiKeyRepository _apiKeyRepo;
  final AccountRepository _accountRepo;
  final AuthPort _authProvider;
  final CachePort _cache;
  final MetricsPort _metricsPort;

  PublicRouter(
    this._config,
    this._packageManagerRouter,
    this._authController,
    this._artifactController,
    this._blobController,
    this._systemController,
    this._apiKeyRepo,
    this._accountRepo,
    this._authProvider,
    this._cache,
    this._metricsPort,
  );

  Router get router {
    final router = Router();

    // Servir o arquivo swagger.yaml diretamente
    router.get('/specs/swagger.yaml', (Request request) {
      return Response.ok(
        File('specs/swagger.yaml').readAsStringSync(),
        headers: {'content-type': 'application/yaml'},
      );
    });

    // 2. System Router (Health Check)
    router.mount('/system', _systemController.router.call);

    // 3. Auth Routes
    router.post('/auth/register', _authController.register);
    router.post('/auth/login', _authController.login);

    // 4. Package Manager Proxy Routes (Legacy + API prefix compatibility)
    // Rota esperada pela documentação: /api/v1/npm, /api/v1/maven, /api/v1/pypi, /api/v1/nuget, /api/v1/docker
    router.mount('/packages', _packageManagerRouter.router.call);

    return router;
  }
}
