import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';
import 'package:sambura_core/infrastructure/services/storage/file_service.dart';

class DownloadController {
  final ArtifactRepository _artifactRepo;
  final FileService _fileService;
  final Logger _log = LoggerConfig.getLogger('DownloadController');

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
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _log.info(
      '[REQ:$requestId] GET /download/$repo/$packageName/$version - Iniciando download',
    );

    try {
      final decodedPackage = Uri.decodeComponent(packageName);

      _log.fine(
        '[REQ:$requestId] Buscando artefato: repo=$repo, package=$decodedPackage, version=$version',
      );
      final artifact = await _artifactRepo.findOne(
        repo,
        decodedPackage,
        version,
      );

      if (artifact == null) {
        _log.warning(
          '[REQ:$requestId] ✗ Artefato não encontrado: $repo/$decodedPackage@$version',
        );
        return Response.notFound('Artefato não encontrado no Samburá');
      }

      _log.info(
        '[REQ:$requestId] Artefato encontrado, iniciando stream: ${artifact.path}',
      );
      final stream = await _fileService.getFileStream(artifact.path);

      final hash = artifact.blob?.hashValue ?? '';
      final mimeType = artifact.blob?.mimeType ?? 'application/octet-stream';
      _log.info(
        '[REQ:$requestId] ✓ Download iniciado: mime=$mimeType, hash=${hash.substring(0, 12)}...',
      );

      return Response.ok(
        stream,
        headers: {
          'Content-Type': mimeType,
          'Content-Disposition': 'attachment; filename="${artifact.path}"',
          'X-Artifact-Hash': hash,
        },
      );
    } catch (e, stack) {
      _log.severe('[REQ:$requestId] ✗ Erro ao processar download', e, stack);
      return Response.internalServerError(
        body: 'Erro ao processar download: $e',
      );
    }
  }
}
