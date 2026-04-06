import 'package:sambura_core/infrastructure/api/controller/artifact/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/package_controller.dart';
import 'package:shelf_router/shelf_router.dart';

class ArtifactRouter {
  final PackageController _packageController;
  final ArtifactController _artifactController;
  final BlobController _blobController;

  ArtifactRouter(
    this._packageController,
    this._artifactController,
    this._blobController,
  );

  Router get router {
    final router = Router();
    // Gestão de Estrutura

    router.get('/package', _packageController.listAll);
    router.get(
      '/repositories/<repoName>/package',
      _packageController.listByRepository,
    );

    router.get(
      '/download/<namespace>/<name>/<version>',
      _artifactController.downloadByVersion,
    );
    router.get('/blobs/<hash>', _blobController.download);

    return router;
  }
}
