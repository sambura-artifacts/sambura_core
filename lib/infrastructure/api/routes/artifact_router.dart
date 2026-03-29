import 'package:sambura_core/infrastructure/api/controller/artifact/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/package_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/repository_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/upload_controller.dart';
import 'package:shelf_router/shelf_router.dart';

class ArtifactRouter {
  final RepositoryController _repositoryController;
  final PackageController _packageController;
  final ArtifactController _artifactController;
  final UploadController _uploadController;
  final BlobController _blobController;

  ArtifactRouter(
    this._repositoryController,
    this._packageController,
    this._artifactController,
    this._uploadController,
    this._blobController,
  );

  Router get router {
    final router = Router();
    // Gestão de Estrutura
    router.get('/repositories', _repositoryController.list);
    router.post('/repositories', _repositoryController.save);

    router.get('/packages', _packageController.listAll);
    router.get(
      '/repositories/<repoName>/packages',
      _packageController.listByRepository,
    );

    router.get(
      '/download/<namespace>/<name>/<version>',
      _artifactController.downloadByVersion,
    );
    router.get('/blobs/<hash>', _blobController.download);
    router.get(
      '/<repositoryName>/<packageName>/<version>',
      _artifactController.resolve,
    );

    // Gestão de Binários
    router.get('/artifacts/<externalId>', _artifactController.getByExternalId);
    router.post('/upload', _uploadController.handle);
    return router;
  }
}
