import 'package:sambura_core/infrastructure/api/controller/artifact/repository_controller.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/infrastructure/api/controller/admin/api_key_controller.dart';

class AdminRouter {
  final ApiKeyController _apiKeyController;
  final RepositoryController _repositoryController;

  AdminRouter(this._apiKeyController, this._repositoryController);

  Router get router {
    final router = Router();

    router.mount('/api-keys', _apiKeyController.router.call);

    router.post('/repositories', _repositoryController.save);

    return router;
  }
}
