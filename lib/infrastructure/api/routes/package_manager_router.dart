import 'package:shelf_router/shelf_router.dart';

import 'package:sambura_core/infrastructure/barrel.dart';

class PackageManagerRouter {
  final NpmRouter _npmRouter;

  PackageManagerRouter(this._npmRouter);

  Router get router {
    final router = Router();

    router.mount('/npm/', _npmRouter.router.call);

    return router;
  }
}
