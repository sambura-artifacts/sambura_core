import 'dart:convert';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/repository_repository.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/npm_controller.dart';

class NpmRouter {
  final NpmController _npmController;
  final RepositoryRepository _repositoryRepository;
  final HttpClientPort _client;
  final Logger _log = LoggerConfig.getLogger('NpmRouter');
  NpmRouter(this._client, this._npmController, this._repositoryRepository);

  Router get router {
    final router = Router();

    // 4. NPM Proxy Routes
    router.get(
      '/<repo>/<package|.*>/-/<filename>',
      _npmController.downloadTarball,
    );
    router.get('/<repo>/<packageName|.*>', _npmController.getPackageMetadata);

    router.post('/<repo>/-/npm/v1/security/advisories/bulk', (
      Request request,
      String repo,
    ) async {
      _log.info(
        'Requisição de análise de segurança recebida para repositório $repo',
      );
      // 1. Lê o payload gerado pelo npm client na máquina do dev
      final body = await request.read().expand((bit) => bit).toList();

      _log.fine('Payload de segurança recebido: ${body.length} bytes');

      final headers = request.headers;

      _log.info('Headers da requisição de segurança: ${jsonEncode(headers)}');

      final repository = await _repositoryRepository.getByName(repo);

      _log.info(
        'Repositório encontrado para análise de segurança: ${jsonEncode(repository!.toMap())}',
      );

      // 2. Verifica se o repositório existe e tem URL remota configurada
      if (repository.remoteUrl == '') {
        _log.warning(
          'Repositório $repo não encontrado para análise de segurança',
        );
        return Response.notFound(
          jsonEncode({'error': 'Repositório $repo não encontrado'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final baseUrl = repository!.remoteUrl.endsWith('/')
          ? repository.remoteUrl.substring(0, repository.remoteUrl.length - 1)
          : repository.remoteUrl;

      final upstreamUrl = Uri.parse(
        '$baseUrl/-/npm/v1/security/advisories/bulk',
      );

      _log.info(
        'Encaminhando requisição de segurança para URL upstream: $upstreamUrl',
      );

      final upstreamResponse = await _client.post(
        upstreamUrl,
        headers: request.headers,
        body: body,
      );

      _log.info(
        'Resposta recebida do NPM para análise de segurança: ${jsonEncode(upstreamResponse.body)}, status code: ${upstreamResponse.statusCode}',
      );

      _log.info(
        'Devolvendo resposta de análise de segurança para o terminal: ${upstreamResponse.statusCode}',
      );

      // 3. Devolve a resposta exata do NPM para o terminal
      return Response(
        upstreamResponse.statusCode,
        body: upstreamResponse.body,
        headers: {'Content-Type': 'application/json'},
      );
    });
    return router;
  }
}
