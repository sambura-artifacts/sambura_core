import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:sambura_core/domain/entities/repository_entity.dart';
import 'package:sambura_core/domain/repositories/repository_repository.dart';
import 'package:sambura_core/infrastructure/api/presenter/error_presenter.dart';
import 'package:sambura_core/infrastructure/api/presenter/artifact/repository_presenter.dart';

class RepositoryController {
  final RepositoryRepository _repository;
  final Logger _log = LoggerConfig.getLogger('RepositoryController');

  RepositoryController(this._repository);

  /// POST /repositories
  Future<Response> save(Request request) async {
    final baseUrl = request.requestedUri.origin;
    final path = request.url.path;

    try {
      final rawBody = await request.readAsString();

      _log.fine('POST /$path | Body recebido: $rawBody');

      if (rawBody.isEmpty) {
        _log.warning('Tentativa de save com body vazio');
        return ErrorPresenter.badRequest(
          "O corpo da requisição não pode estar vazio.",
          path,
          baseUrl,
        );
      }

      final payload = jsonDecode(rawBody);

      // Usando o fromMap que a gente blindou na Entidade
      final entity = RepositoryEntity.fromMap(payload);

      _log.info(
        'Processando repositório: ${entity.name} (namespace: ${entity.namespace})',
      );

      final saved = await _repository.save(entity);

      _log.info('Repositório salvo com sucesso! ID: ${saved.id}');

      return Response.ok(
        jsonEncode(RepositoryPresenter.toJson(saved, baseUrl)),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      _log.severe('Erro crítico ao salvar repositório', e, stack);

      return ErrorPresenter.internalServerError(
        "Falha ao salvar as configurações do repositório.",
        path,
        baseUrl,
        error: e,
        stack: stack,
      );
    }
  }

  /// GET /repositories
  Future<Response> list(Request request) async {
    final params = request.url.queryParameters;
    final limit = int.tryParse(params['limit'] ?? '10') ?? 10;
    final offset = int.tryParse(params['offset'] ?? '0') ?? 0;
    final baseUrl = request.requestedUri.origin;
    final path = request.url.path;

    _log.info('GET /$path | limit: $limit, offset: $offset');

    try {
      final repos = await _repository.list(limit: limit, offset: offset);
      _log.info('Listagem concluída: ${repos.length} itens encontrados');

      return Response.ok(
        RepositoryPresenter.listToJson(
          items: repos,
          baseUrl: baseUrl,
          limit: limit,
          offset: offset,
        ),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      _log.severe('Erro na listagem de repositórios', e, stack);
      return ErrorPresenter.internalServerError(
        "Erro na listagem",
        path,
        baseUrl,
        error: e,
        stack: stack,
      );
    }
  }
}
