// lib/infrastructure/api/controller/package_controller.dart
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/package_repository.dart';
import 'package:sambura_core/infrastructure/api/presenter/package_presenter.dart';
import 'package:sambura_core/infrastructure/api/presenter/error_presenter.dart';

class PackageController {
  final PackageRepository _repository;
  final Logger _log = LoggerConfig.getLogger('PackageController');

  PackageController(this._repository);

  /// GET /admin/packages (Lista TUDO no sistema),
  Future<Response> listAll(Request request) async {
    final baseUrl = request.requestedUri.origin;
    final params = request.url.queryParameters;
    final limit = int.tryParse(params['limit'] ?? '50') ?? 50;
    final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

    try {
      final packages = await _repository.listAll(limit: limit, offset: offset);

      // Usamos o Presenter, mas passando 'global' como nome do repo
      return Response.ok(
        PackagePresenter.renderList(packages, 'global', baseUrl, limit, offset),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      _log.severe('Erro ao listar todos os pacotes', e, stack);
      return ErrorPresenter.internalServerError(
        "Erro global na listagem.",
        request.url.path,
        baseUrl,
      );
    }
  }

  /// GET /admin/repositories/<repoName>/packages
  Future<Response> listByRepository(Request request, String repoName) async {
    final baseUrl = request.requestedUri.origin;
    final params = request.url.queryParameters;
    final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
    final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

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
      _log.severe('Erro no repositório $repoName', e, stack);
      return ErrorPresenter.internalServerError(
        "Erro no repo $repoName.",
        request.url.path,
        baseUrl,
      );
    }
  }
}
