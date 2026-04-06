import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class NamespaceController {
  final NamespaceRepository _namespaceRepository;
  final Logger _log = LoggerConfig.getLogger('RepositoryController');

  NamespaceController(this._namespaceRepository);

  /// POST /namespace
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
      final entity = NamespaceEntity.fromMap(payload);

      _log.info(
        'Processando repositório: ${entity.name} (namespace: ${entity.escope})',
      );

      final saved = await _namespaceRepository.save(entity);

      _log.info('Repositório salvo com sucesso! ID: ${saved.id}');

      return Response.ok(
        jsonEncode(NamespacePresenter.toJson(saved, baseUrl)),
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
      final repos = await _namespaceRepository.list(
        limit: limit,
        offset: offset,
      );
      _log.info('Listagem concluída: ${repos.length} itens encontrados');

      return Response.ok(
        NamespacePresenter.listToJson(
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
