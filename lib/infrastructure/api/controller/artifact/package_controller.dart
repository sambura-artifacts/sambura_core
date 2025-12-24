// lib/infrastructure/api/controller/artifact/package_controller.dart
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/package_repository.dart';
import 'package:sambura_core/infrastructure/api/presenter/artifact/package_presenter.dart';
import 'package:sambura_core/infrastructure/api/presenter/error_presenter.dart';

class PackageController {
  final PackageRepository _repository;
  final Logger _log = LoggerConfig.getLogger('PackageController');

  PackageController(this._repository);

  /// GET /admin/packages (Lista TUDO no sistema),
  Future<Response> listAll(Request request) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final baseUrl = request.requestedUri.origin;
    final params = request.url.queryParameters;
    final limit = int.tryParse(params['limit'] ?? '50') ?? 50;
    final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

    _log.info(
      '[REQ:$requestId] GET /admin/packages - Listando todos os pacotes (limit=$limit, offset=$offset)',
    );

    try {
      final packages = await _repository.listAll(limit: limit, offset: offset);

      _log.info('[REQ:$requestId] ✓ ${packages.length} pacotes encontrados');
      // Usamos o Presenter, mas passando 'global' como nome do repo
      return Response.ok(
        PackagePresenter.renderList(packages, 'global', baseUrl, limit, offset),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      _log.severe(
        '[REQ:$requestId] ✗ Erro ao listar todos os pacotes',
        e,
        stack,
      );
      return ErrorPresenter.internalServerError(
        "Erro global na listagem.",
        request.url.path,
        baseUrl,
      );
    }
  }

  /// GET /admin/repositories/<repoName>/packages
  Future<Response> listByRepository(Request request, String repoName) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final baseUrl = request.requestedUri.origin;
    final params = request.url.queryParameters;
    final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
    final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

    _log.info(
      '[REQ:$requestId] GET /admin/repositories/$repoName/packages (limit=$limit, offset=$offset)',
    );

    try {
      final packages = await _repository.listByRepositoryName(
        repoName,
        limit: limit,
        offset: offset,
      );

      _log.info(
        '[REQ:$requestId] ✓ ${packages.length} pacotes encontrados no repositório $repoName',
      );
      return Response.ok(
        PackagePresenter.renderList(packages, repoName, baseUrl, limit, offset),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      _log.severe(
        '[REQ:$requestId] ✗ Erro ao listar pacotes do repositório $repoName',
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
