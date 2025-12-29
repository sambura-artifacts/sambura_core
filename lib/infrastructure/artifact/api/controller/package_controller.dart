import 'dart:convert';
import 'package:sambura_core/application/package/usecase/proxy_package_metadata_usecase.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/package/usecase/get_package_metadata_usecase.dart'; // Importe o UseCase
import 'package:sambura_core/infrastructure/artifact/api/presenter/package_presenter.dart';
import 'package:sambura_core/infrastructure/shared/api/error_presenter.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';

class PackageController {
  final PackageRepository _repository;
  final GetPackageMetadataUseCase _getMetadataUseCase;
  final ProxyPackageMetadataUseCase _proxyMetadataUseCase;
  final Logger _log = LoggerConfig.getLogger('PackageController');

  PackageController(
    this._repository,
    this._getMetadataUseCase,
    this._proxyMetadataUseCase,
  );

  Future<Response> getMetadata(Request request) async {
    final packageName = Uri.decodeComponent(request.params['name'] ?? '');
    final repoName = request.params['repo'] ?? 'private-repo';

    try {
      // Tenta buscar metadados locais (Pacotes privados/já cacheados)
      var metadata = await _getMetadataUseCase.execute(repoName, packageName);

      if (metadata == null) {
        _log.info(
          '🌐 Cache Miss no Metadata: consultando Upstream para $packageName',
        );

        // Fallback para o Proxy (Lazy Mirroring de Metadados)
        metadata = await _proxyMetadataUseCase.execute(
          packageName,
          repoName: repoName,
        );
      }

      if (metadata == null) {
        return Response.notFound(jsonEncode({'error': 'Not found'}));
      }

      return Response.ok(
        jsonEncode(metadata),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      rethrow;
    }
  }

  // --- MÉTODOS DE ADMIN (MANTIDOS) ---

  Future<Response> listAll(Request request) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final baseUrl = request.requestedUri.origin;
    final params = request.url.queryParameters;
    final limit = int.tryParse(params['limit'] ?? '50') ?? 50;
    final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

    _log.info('[REQ:$requestId] GET /admin/packages - Listagem global');

    try {
      final packages = await _repository.listAll(limit: limit, offset: offset);
      return Response.ok(
        PackagePresenter.renderList(packages, 'global', baseUrl, limit, offset),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      _log.severe('[REQ:$requestId] ✗ Erro global na listagem', e, stack);
      return ErrorPresenter.internalServerError(
        "Erro global.",
        request.url.path,
        baseUrl,
      );
    }
  }

  Future<Response> listByRepository(Request request, String repoName) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final baseUrl = request.requestedUri.origin;
    final params = request.url.queryParameters;
    final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
    final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

    _log.info('[REQ:$requestId] GET /admin/repositories/$repoName/packages');

    try {
      final packages = await _repository.listByRepositoryName(
        repoName,
        limit: limit,
        offset: offset,
      );
      return Response.ok(
        PackagePresenter.renderList(packages, repoName, baseUrl, limit, offset),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      _log.severe(
        '[REQ:$requestId] ✗ Erro ao listar pacotes do repo $repoName',
        e,
        stack,
      );
      return ErrorPresenter.internalServerError(
        "Erro no repo $repoName.",
        request.url.path,
        baseUrl,
      );
    }
  }
}
