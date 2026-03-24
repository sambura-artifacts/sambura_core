import 'dart:io';

import 'package:sambura_core/infrastructure/api/controller/artifact/npm_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/maven_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/pypi_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/nuget_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/docker_controller.dart';
import 'package:sambura_core/config/env.dart';
import 'package:sambura_core/infrastructure/api/controller/system/metrics_controller.dart';
import 'package:sambura_core/infrastructure/api/middleware/error_handler_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/infrastructure/api/controller/auth/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/system/system_controller.dart';
import 'package:sambura_core/infrastructure/api/middleware/auth_middleware.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';

class PublicRouter {
  final EnvConfig _config;
  final AuthController _authController;
  final ArtifactController _artifactController;
  final NpmController _npmController;
  final MavenController _mavenController;
  final PypiController _pypiController;
  final NugetController _nugetController;
  final DockerController _dockerController;
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
    this._npmController,
    this._mavenController,
    this._pypiController,
    this._nugetController,
    this._dockerController,
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

    // Servir o arquivo swagger.yaml diretamente
    router.get('/specs/swagger.yaml', (Request request) {
      return Response.ok(
        File('specs/swagger.yaml').readAsStringSync(),
        headers: {'content-type': 'application/yaml'},
      );
    });
    router.get('/metrics', _metricsController.getMetrics);

    // 2. System Router (Health Check)
    router.mount('/system', _systemController.router.call);

    // 3. Auth Routes
    router.post('/auth/register', _authController.register);
    router.post('/auth/login', _authController.login);

    // 4. NPM Proxy Routes
    router.get(
      '/npm/<repo>/<package|.*>/-/<filename>',
      _npmController.downloadTarball,
    );
    router.get(
      '/npm/<repo>/<packageName|.*>',
      _npmController.getPackageMetadata,
    );

    // 5. Maven Routes
    router.get(
      '/maven/<repo>/<groupId>/<artifactId>/<version>/<filename>',
      _mavenController.downloadArtifact,
    );
    router.get(
      '/maven/<repo>/<groupId>/<artifactId>/maven-metadata.xml',
      _mavenController.getMetadata,
    );

    // 6. PyPI Routes
    router.get(
      '/pypi/<repo>/simple/<package>/',
      _pypiController.getSimpleMetadata,
    );
    router.get(
      '/pypi/<repo>/packages/<path|.*>',
      _pypiController.downloadArtifact,
    );

    // 7. NuGet Routes
    router.get('/nuget/<repo>/v3/index.json', _nugetController.getServiceIndex);
    router.get(
      '/nuget/<repo>/v3-flatcontainer/<package>/<version>/<filename>',
      _nugetController.downloadPackage,
    );
    router.get('/nuget/<repo>/<any|.*>', _nugetController.proxyResource);

    // 8. Docker Registry Routes
    router.get('/docker/<repo>/v2/', _dockerController.checkApi);
    router.get(
      '/docker/<repo>/v2/<name|.*>/manifests/<reference>',
      _dockerController.getManifest,
    );
    router.get(
      '/docker/<repo>/v2/<name|.*>/blobs/<digest>',
      _dockerController.downloadBlob,
    );

    // 5. Pipeline Protegida com Métricas
    final secureResolverPipeline = Pipeline()
        .addMiddleware(errorHandler(_config.publicOrigin, _metricsPort))
        .addMiddleware(
          authMiddleware(
            _accountRepo,
            _apiKeyRepo,
            _authProvider,
            _cache,
            _metricsPort,
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
