import 'package:sambura_core/infrastructure/api/controller/upload_controller.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/infrastructure/api/controller/api_key_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/repository_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/package_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact_controller.dart';

class AdminRouter {
  final RepositoryController _repositoryController;
  final PackageController _packageController;
  final ArtifactController _artifactController;
  final ApiKeyController _apiKeyController;
  final UploadController _uploadController;

  AdminRouter(
    this._repositoryController,
    this._packageController,
    this._artifactController,
    this._apiKeyController,
    this._uploadController,
  );

  Router get router {
    final router = Router();

    // --- Repositories ---
    router.get('/repositories', _repositoryController.list);
    router.post('/repositories', _repositoryController.save);

    // --- Packages (Global e por Repo) ---
    router.get('/packages', _packageController.listAll);
    router.get(
      '/repositories/<repoName>/packages',
      _packageController.listByRepository,
    );

    // --- Artifacts ---
    router.get('/artifacts/<externalId>', _artifactController.getByExternalId);

    // --- Api Keys (Onde o filho chora e o admin não vê) ---
    // Montamos o sub-router do controller no path /api-keys
    router.mount('/api-keys', _apiKeyController.router.call);

    router.post('/upload', _uploadController.handle);

    return router;
  }
}
