import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';

import 'package:sambura_core/infrastructure/api/controller/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/repository_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/package_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/blob_controller.dart';

/// Gerenciador de rotas da API Samburá.
/// Mapeia os endpoints para os UseCases através dos Controllers.
class ApiRouter {
  final ArtifactController _artifactController;
  final PackageController _packageController;
  final RepositoryController _repositoryController;
  final BlobController _blobController;

  ApiRouter(
    this._artifactController,
    this._packageController,
    this._repositoryController,
    this._blobController,
  );

  Handler get handler {
    final router = Router();

    // =========================================================================
    // DOCUMENTAÇÃO (Swagger)
    // =========================================================================
    final swaggerHandler = SwaggerUI(
      'specs/swagger.yaml',
      title: 'Samburá Docs - API de Elite',
    );

    router.all('/docs/<any|.*>', swaggerHandler.call);

    // =========================================================================
    // ADMIN: Repositories (Namespaces/Silos)
    // =========================================================================

    // Lista todos os repositórios (paginado)
    router.get('/admin/repositories', _repositoryController.list);

    // Cria um novo repositório
    router.post('/admin/repositories', _repositoryController.save);

    // =========================================================================
    // ADMIN: Packages (Gestão de pacotes dentro dos repos)
    // =========================================================================

    // Lista os pacotes de um repositório específico
    router.get(
      '/admin/repositories/<repoName>/packages',
      _packageController.listByRepository,
    );

    // =========================================================================
    // RESOLUTION: O Core do Proxy (Nome/Versão)
    // =========================================================================

    /// Resolve a localização do artefato (Proxy para NPM ou Cache Local)
    router.get('/<repositoryName>/<packageName>/<version>', (
      Request request,
      String repositoryName,
      String packageName,
      String version,
    ) {
      return _artifactController.resolve(
        request,
        repositoryName,
        packageName,
        version,
      );
    });

    // =========================================================================
    // ARTIFACTS: Gestão de Metadados e Upload Manual
    // =========================================================================

    /// Busca metadados de um artefato específico pelo seu UUID
    router.get('/artifacts/<externalId>', _artifactController.getByExternalId);

    /// Upload manual seguindo a hierarquia completa
    router.post(
      '/<repositoryName>/<namespace>/<packageName>/<version>/<path|.*>',
      _artifactController.upload,
    );

    // =========================================================================
    // BLOBS: Acesso aos binários (Storage)
    // =========================================================================

    /// Download direto do binário pelo seu Hash (Silo/MinIO/FS)
    router.get('/blobs/<hash>', _blobController.download);

    return router.call;
  }
}
