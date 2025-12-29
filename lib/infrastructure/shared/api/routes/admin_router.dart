import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/infrastructure/auth/api/api_key_controller.dart';

class AdminRouter {
  final ApiKeyController _apiKeyController;

  AdminRouter(this._apiKeyController);

  Router get router {
    final router = Router();

    router.mount('/api-keys', _apiKeyController.router.call);

    return router;
  }
}
