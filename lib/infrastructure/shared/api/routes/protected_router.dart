import 'package:sambura_core/infrastructure/shared/api/routes/artifact_router.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/infrastructure/auth/api/auth_controller.dart';
import 'package:sambura_core/infrastructure/shared/api/routes/admin_router.dart';

class ProtectedRouter {
  final AuthController _authController;
  final AdminRouter _adminRouter;
  final ArtifactRouter _artifactRouter;

  ProtectedRouter(
    this._authController,
    this._adminRouter,
    this._artifactRouter,
  );

  Router get router {
    final router = Router();

    router.post('/auth/register', _authController.register);

    router.mount('/admin', _adminRouter.router.call);

    router.mount('/artifacts', _artifactRouter.router.call);

    return router;
  }
}
