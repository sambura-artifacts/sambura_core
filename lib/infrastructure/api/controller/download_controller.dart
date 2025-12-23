import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';
import 'package:sambura_core/infrastructure/services/file_service.dart';

class DownloadController {
  final ArtifactRepository _artifactRepo;
  final FileService _fileService;

  DownloadController(this._artifactRepo, this._fileService);

  Router get router {
    final router = Router();
    router.get('/<repo>/<packageName>/<version>', _handleDownload);
    return router;
  }

  Future<Response> _handleDownload(
    Request request,
    String repo,
    String packageName,
    String version,
  ) async {
    try {
      final decodedPackage = Uri.decodeComponent(packageName);

      final artifact = await _artifactRepo.findOne(
        repo,
        decodedPackage,
        version,
      );

      if (artifact == null) {
        return Response.notFound('Artefato não encontrado no Samburá');
      }

      final stream = await _fileService.getFileStream(artifact.path);

      return Response.ok(
        stream,
        headers: {
          'Content-Type': artifact.blob?.mimeType ?? 'application/octet-stream',
          'Content-Disposition': 'attachment; filename="${artifact.path}"',
          'X-Artifact-Hash': artifact.blob?.hashValue ?? '',
        },
      );
    } catch (e) {
      return Response.internalServerError(
        body: 'Erro ao processar download: $e',
      );
    }
  }
}
