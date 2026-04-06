import 'package:sambura_core/infrastructure/api/controller/artifact/namespace_controller.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/infrastructure/api/controller/admin/api_key_controller.dart';

class AdminRouter {
  final ApiKeyController _apiKeyController;
  final NamespaceController _namespaceController;

  AdminRouter(this._apiKeyController, this._namespaceController);

  Router get router {
    final router = Router();

    router.mount('/api-key', _apiKeyController.router.call);

    router.get('/namespace', _namespaceController.list);
    router.post('/namespace', _namespaceController.save);

    return router;
  }
}
