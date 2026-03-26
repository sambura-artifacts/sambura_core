import 'package:sambura_core/infrastructure/api/routes/artifact_router.dart';
import 'package:sambura_core/infrastructure/api/routes/package_manager_router.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/infrastructure/api/controller/auth/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/routes/admin_router.dart';

class ProtectedRouter {
  final AuthController _authController;
  final AdminRouter _adminRouter;
  final ArtifactRouter _artifactRouter;
  final PackageManagerRouter _packageManagerRouter;

  ProtectedRouter(
    this._authController,
    this._adminRouter,
    this._artifactRouter,
    this._packageManagerRouter,
  );

  Router get router {
    final router = Router();

    // Auth routes (protected)
    router.post('/auth/refresh', _authController.refreshToken);

    router.post('/auth/login', _authController.login);

    router.post('/auth/register', _authController.register);

    router.mount('/admin', _adminRouter.router.call);

    router.mount('/artifacts', _artifactRouter.router.call);

    // Compatibilidade de mount: /packages e / (para /api/v1/npm etc)
    router.mount('/packages', _packageManagerRouter.router.call);
    router.mount('/', _packageManagerRouter.router.call);

    return router;
  }
}
