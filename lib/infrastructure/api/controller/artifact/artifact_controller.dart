import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class ArtifactController {
  final CreateArtifactUsecase _createArtifactUseCase;
  final GetArtifactDownloadStreamUsecase _getArtifactDownloadStreamUsecase;
  final NpmProxyPackageMetadataUseCase _npmProxyPackageMetadataUseCase;
  final GenerateApiKeyUsecase _generateApiKeyUsecase;
  final MetricsPort _metrics;
  final Logger _log = LoggerConfig.getLogger('ArtifactController');

  ArtifactController(
    this._createArtifactUseCase,
    this._getArtifactDownloadStreamUsecase,
    this._npmProxyPackageMetadataUseCase,
    this._generateApiKeyUsecase,
    this._metrics,
  );

  /// Download genérico por versão (Útil para resolvers internos)
  Future<Response> downloadByVersion(
    Request request,
    String namespace,
    String name,
    String version,
  ) {
    final path = request.url.path;

    return _measure('GET', path, () async {
      try {
        final local = await _getArtifactDownloadStreamUsecase.execute(
          namespace: namespace,
          name: name,
          version: version,
        );

        if (local != null) {
          _log.info('🚀 Cache Hit: $name@$version');
          return Response.ok(
            local.stream,
            headers: {
              'Content-Type': 'application/octet-stream',
              'Content-Length': local.blob.sizeBytes.toString(),
            },
          );
        }

        return Response.notFound(
          jsonEncode({'error': 'Artefato não encontrado no cache local.'}),
        );
      } catch (e, stack) {
        _log.severe('❌ Erro no download genérico', e, stack);
        return ErrorPresenter.internalServerError(
          "Erro no download.",
          request.url.path,
          request.requestedUri.origin,
        );
      }
    });
  }

  /// POST /upload/:repository/:namespace/:package/:version
  Future<Response> upload(
    Request request,
    String repo,
    String ns,
    String pkg,
    String ver,
  ) {
    final path = request.url.path;

    return _measure('POST', path, () async {
      try {
        // Extrai o caminho relativo (ex: nome do arquivo .tgz)
        final relativePath = request.url.pathSegments.skip(3).join('/');

        final input = InfraestructureArtifactInput(
          namespace: repo,
          packageName: pkg,
          version: ver,
          fileName: relativePath,
        );

        _log.info('📤 Recebendo upload: $pkg@$ver no repo $repo');

        final artifact = await _createArtifactUseCase.execute(
          input,
          request.read(),
        );

        if (artifact == null) {
          return Response.notFound(
            jsonEncode({'error': 'Erro ao criar artefato.'}),
          );
        }

        return ArtifactPresenter.createArtifact(
          artifact,
          request.requestedUri.origin,
        );
      } catch (e) {
        // O _measure capturará o erro e registrará como status 500 nas métricas
        rethrow;
      }
    });
  }

  /// POST /generate-api-key
  /// Apenas administradores podem gerar novas chaves
  Future<Response> generateApiKey(Request request) {
    final path = request.url.path;

    return _measure('POST', path, () async {
      final user = request.context['user'] as AccountEntity;

      if (user.role.value != 'admin') {
        return Response.forbidden(
          jsonEncode({'error': 'Acesso negado: Requer privilégios de Admin'}),
        );
      }

      try {
        final payload = jsonDecode(await request.readAsString());
        final keyName = payload['name'] ?? 'default-key';
        final expiresInDays = payload['expires_in_days'] ?? 30;

        final result = await _generateApiKeyUsecase.execute(
          accountId: user.id!,
          keyName: keyName,
          expiresInDays: expiresInDays,
        );

        return Response.ok(
          jsonEncode({
            'message': 'API Key gerada. Guarde-a em local seguro!',
            'api_key': result.plainKey,
            'name': result.name,
          }),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Falha ao gerar chave'}),
        );
      }
    });
  }

  /// GET /search/:repo
  /// Proxy de busca para o NPM Registry
  Future<Response> searchPackages(Request request) {
    final path = request.url.path;

    return _measure('GET', path, () async {
      final repo = request.params['repo']!;
      final queryParams = request.url.queryParameters;

      try {
        final result = await _npmProxyPackageMetadataUseCase.execute(
          '/-/v1/search',
          repoName: repo,
          queryParams: queryParams,
        );

        if (result == null) {
          return Response.notFound(jsonEncode({'error': 'Sem resultados'}));
        }

        return Response.ok(
          jsonEncode(result),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e, stack) {
        _log.severe('❌ Erro na busca NPM', e, stack);
        return Response.internalServerError(
          body: jsonEncode({'error': 'Erro na busca'}),
        );
      }
    });
  }

  Future<Response> _measure(
    String method,
    String path,
    Future<Response> Function() action,
  ) async {
    final sw = Stopwatch()..start();
    try {
      final response = await action();
      sw.stop();
      // Registra no Prometheus: convertemos ms para segundos para o padrão Histogram
      _metrics.recordHttpDuration(
        method,
        path,
        response.statusCode,
        sw.elapsedMilliseconds / 1000.0,
      );
      _log.info('⏱️ [$method] $path finalizado em ${sw.elapsedMilliseconds}ms');
      return response;
    } catch (e) {
      sw.stop();
      _metrics.recordHttpDuration(
        method,
        path,
        500,
        sw.elapsedMilliseconds / 1000.0,
      );
      rethrow;
    }
  }
}
