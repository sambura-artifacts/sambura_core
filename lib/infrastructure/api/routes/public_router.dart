import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:sambura_core/infrastructure/barrel.dart';

class PublicRouter {
  final PackageManagerRouter _packageManagerRouter;
  final AuthController _authController;
  final SystemController _systemController;

  PublicRouter(
    this._packageManagerRouter,
    this._authController,
    this._systemController,
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
