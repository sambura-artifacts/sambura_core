import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class PackageController {
  final PackageRepository _repository;
  final NpmGetPackageMetadataUseCase _getMetadataUseCase;
  final NpmProxyPackageMetadataUseCase _proxyMetadataUseCase;
  final Logger _log = LoggerConfig.getLogger('PackageController');

  PackageController(
    this._repository,
    this._getMetadataUseCase,
    this._proxyMetadataUseCase,
  );

  Future<Response> getMetadata(
    Request request,
    String repo,
    String packageName,
  ) async {
    try {
      // Tenta buscar metadados locais (Pacotes privados/já cacheados)

      var metadata = await _getMetadataUseCase.execute(
        InfraestructureArtifactInput(namespace: repo, packageName: packageName),
      );

      if (metadata == null) {
        _log.info(
          '🌐 Cache Miss no Metadata: consultando Upstream para $packageName',
        );

        // Fallback para o Proxy (Lazy Mirroring de Metadados)
        metadata = await _proxyMetadataUseCase.execute(
          packageName,
          repoName: repo,
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
