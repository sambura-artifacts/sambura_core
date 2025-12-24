import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/package_repository.dart';
import 'package:sambura_core/application/usecase/package/get_package_metadata_usecase.dart'; // Importe o UseCase
import 'package:sambura_core/infrastructure/api/presenter/artifact/package_presenter.dart';
import 'package:sambura_core/infrastructure/api/presenter/error_presenter.dart';

class PackageController {
  final PackageRepository _repository;
  final GetPackageMetadataUseCase _getMetadataUseCase; // Injetado aqui
  final Logger _log = LoggerConfig.getLogger('PackageController');

  PackageController(this._repository, this._getMetadataUseCase);

  /// GET /api/v1/npm/private-repo/<name>
  /// Este é o endpoint que o NPM CLI consulta antes de publicar ou instalar.
  Future<Response> getMetadata(Request request) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final baseUrl = request.requestedUri.origin;

    // Extrai o nome do pacote (decodificando @scopes se houver)
    final packageName = Uri.decodeComponent(request.params['name'] ?? '');
    // Nome do repo fixo ou extraído do context/path
    final repoName = 'private-repo';

    _log.info('[REQ:$requestId] GET Metadata para NPM - package=$packageName');

    try {
      final metadata = await _getMetadataUseCase.execute(repoName, packageName);

      if (metadata == null) {
        _log.warning('[REQ:$requestId] ✗ Pacote não encontrado: $packageName');
        // 404 é a resposta esperada pelo NPM para novos pacotes
        return Response.notFound(
          jsonEncode({'error': 'Not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      _log.info('[REQ:$requestId] ✓ Metadata enviado com sucesso');
      return Response.ok(
        jsonEncode(metadata),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      _log.severe('[REQ:$requestId] ✗ Erro ao gerar metadata NPM', e, stack);
      return ErrorPresenter.internalServerError(
        "Erro no metadata.",
        request.url.path,
        baseUrl,
      );
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
