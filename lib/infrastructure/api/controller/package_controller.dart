import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:sambura_core/domain/repositories/package_repository.dart';
import 'package:sambura_core/infrastructure/api/presenter/error_presenter.dart';

class PackageController {
  final PackageRepository _repository;
  final Logger _log = LoggerConfig.getLogger('PackageController');

  PackageController(this._repository);

  /// GET /admin/repositories/<repoName>/packages
  /// Unificando a lógica e adicionando limite/offset
  Future<Response> listByRepository(Request request, String repoName) async {
    final baseUrl = request.requestedUri.origin;
    final params = request.url.queryParameters;

    // Paginação pra não travar o sistema
    final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
    final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

    _log.info(
      'Listando pacotes do repositório: $repoName (limit=$limit, offset=$offset)',
    );

    try {
      // Busca no banco usando o repositório
      final packages = await _repository.listByRepositoryName(
        repoName,
        limit: limit,
        offset: offset,
      );

      _log.info(
        'Encontrados ${packages.length} pacotes no repositório $repoName',
      );

      return Response.ok(
        jsonEncode({
          'metadata': {
            'repository': repoName,
            'count': packages.length,
            'limit': limit,
            'offset': offset,
            'next':
                '$baseUrl/admin/repositories/$repoName/packages?limit=$limit&offset=${offset + limit}',
          },
          'items': packages
              .map(
                (p) => {
                  'id': p.id,
                  'name': p.name,
                  'createdAt': p.createdAt.toIso8601String(),
                  '_links': {
                    'self':
                        '$baseUrl/admin/repositories/$repoName/packages/${p.name}',
                    'versions': '$baseUrl/$repoName/${p.name}',
                  },
                },
              )
              .toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      _log.severe('Erro ao listar pacotes do repositório $repoName', e, stack);
      return ErrorPresenter.internalServerError(
        "Erro ao listar os pacotes do repositório $repoName.",
        request.url.path,
        baseUrl,
        error: e,
        stack: stack,
      );
    }
  }
}
