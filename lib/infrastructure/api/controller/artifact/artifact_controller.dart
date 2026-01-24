import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:sambura_core/application/usecase/api_key/generate_api_key_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/download_artifact_tarball_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/get_artifact_by_id_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/get_artifact_download_stream_usecase.dart';
import 'package:sambura_core/application/usecase/package/proxy_package_metadata_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/get_artifact_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/create_artifact_usecase.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/api/helpers/package_path_parser.dart';
import 'package:sambura_core/infrastructure/api/presenter/artifact/artifact_presenter.dart';
import 'package:sambura_core/infrastructure/api/presenter/error_presenter.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/application/exceptions/exceptions.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/domain/entities/entities.dart';
import 'package:sambura_core/domain/exceptions/exceptions.dart';

class ArtifactController {
  final CreateArtifactUsecase _createArtifactUseCase;
  final GetArtifactUseCase _getArtifactUseCase;
  final GetArtifactByIdUseCase _getByIdUseCase;
  final GetArtifactDownloadStreamUsecase _getArtifactDownloadStreamUsecase;
  final GenerateApiKeyUsecase _generateApiKeyUsecase;
  final ProxyPackageMetadataUseCase _proxyPackageMetadataUseCase;
  final DownloadArtifactTarballUseCase _downloadArtifactTarballUseCase;
  final MetricsPort _metrics;
  final Logger _log = LoggerConfig.getLogger('ArtifactController');

  ArtifactController(
    this._createArtifactUseCase,
    this._getArtifactUseCase,
    this._getByIdUseCase,
    this._getArtifactDownloadStreamUsecase,
    this._generateApiKeyUsecase,
    this._proxyPackageMetadataUseCase,
    this._downloadArtifactTarballUseCase,
    this._metrics,
  );

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

        _log.info('🌐 Mirroring: $name@$version');

        final input = ArtifactInput(
          repositoryName: namespace,
          namespace: namespace,
          packageName: name,
          version: version,
          path: '$name/-/$name-$version.tgz',
        );

        final stream = await _downloadArtifactTarballUseCase.executeProxyStream(
          remoteUrl: 'https://registry.npmjs.org/$name/-/$name-$version.tgz',
          input: input,
        );

        return Response.ok(
          stream,
          headers: {
            'Content-Type': 'application/octet-stream',
            'X-Sambura-Cache': 'MISS',
          },
        );
      } catch (e, stack) {
        _log.severe('❌ Erro no download por versão', e, stack);
        return ErrorPresenter.internalServerError(
          "Erro no download.",
          request.url.path,
          request.requestedUri.origin,
        );
      }
    });
  }

  Future<Response> downloadTarball(Request request) {
    final path = request.url.path;

    return _measure('GET', path, () async {
      try {
        final repo = request.params['repo']!.trim();
        final package = request.params['package']!.trim();
        final filename = request.params['filename']!.replaceAll(';', '').trim();

        SecurityValidator.validatePackagePath(package);

        final nameOnly = PackagePathParser.extractName(package);
        final version = PackagePathParser.extractVersion(filename);

        // 1. Tenta buscar do Silo Local
        final local = await _getArtifactDownloadStreamUsecase.execute(
          namespace: repo,
          name: nameOnly,
          version: version,
        );

        if (local != null) {
          return Response.ok(
            local.stream,
            headers: {
              'Content-Type': 'application/octet-stream',
              'Content-Length': local.blob.sizeBytes.toString(),
            },
          );
        }

        // 2. Fallback para Proxy (NPM Registry)
        final input = ArtifactInput(
          repositoryName: repo,
          namespace: repo,
          packageName: nameOnly,
          version: version,
          path: '$package/-/$filename',
        );

        final stream = await _downloadArtifactTarballUseCase.executeProxyStream(
          remoteUrl: 'https://registry.npmjs.org/$package/-/$filename',
          input: input,
        );

        return Response.ok(
          stream,
          headers: {'Content-Type': 'application/octet-stream'},
        );
      } on RepositoryNotFoundException catch (e) {
        return Response.notFound(jsonEncode({'error': e.toString()}));
      } on ExternalServiceUnavailableException catch (e) {
        _log.warning('🌐 NPM indisponível para $path: ${e.message}');
        return Response.internalServerError(
          body: jsonEncode({
            'error': 'Registro externo (NPM) indisponível no momento.',
          }),
        );
      } catch (e, stack) {
        _log.severe('💥 Erro inesperado no download:', e, stack);
        rethrow;
      }
    });
  }

  /// GET /npm/:repo/:packageName
  /// Ponto central para metadados e redirecionamento de tarballs (Lazy Mirroring)
  Future<Response> getPackageMetadata(Request request) {
    final path = request.url.path;

    return _measure('GET', path, () async {
      final baseUrl = request.requestedUri.origin;
      final instance = request.url.path;

      try {
        final repo = request.params['repo'] ?? '';
        final packageName = request.params['packageName'] ?? '';

        SecurityValidator.validateGenericInput(repo);
        SecurityValidator.validatePackagePath(packageName);

        // 1. Tratamento de Binários (.tgz)
        if (packageName.endsWith('.tgz')) {
          return await _handleTarballRequest(repo, packageName);
        }

        // 2. Tratamento de Ações de Registro (ex: -/v1/search)
        if (packageName.startsWith('-/')) {
          final result = await _proxyPackageMetadataUseCase.execute(
            packageName,
            repoName: repo,
            queryParams: request.url.queryParameters,
          );
          return Response.ok(
            jsonEncode(result),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // 3. Metadados de Pacote (JSON)
        final result = await _proxyPackageMetadataUseCase.execute(
          packageName,
          repoName: repo,
          queryParams: request.url.queryParameters,
        );

        if (result == null) {
          return Response.notFound(jsonEncode({'error': 'Not found'}));
        }

        return Response.ok(
          result is Map ? jsonEncode(result) : result,
          headers: {'Content-Type': 'application/json'},
        );
      } on SecurityException catch (e) {
        _log.warning('🛡️ Segurança: ${e.message}');
        _metrics.recordViolation('invalid_package_format');
        return Response.forbidden('Requisição negada por segurança.');
      } catch (e, stack) {
        _log.severe('❌ Erro no Metadata:', e, stack);
        return ErrorPresenter.internalServerError(
          "Erro ao processar metadados.",
          instance,
          baseUrl,
        );
      }
    });
  }

  /// Lógica interna para gerenciar o Stream do Tarball
  Future<Response> _handleTarballRequest(String repo, String path) async {
    final nameOnly = PackagePathParser.extractName(path);
    final version = PackagePathParser.extractVersion(path);

    // Tenta cache local primeiro
    final local = await _getArtifactDownloadStreamUsecase.execute(
      namespace: repo,
      name: nameOnly,
      version: version,
    );

    if (local != null) {
      _log.info('🚀 Cache Hit: $path');
      return Response.ok(
        local.stream,
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': local.blob.sizeBytes.toString(),
        },
      );
    }

    // Cache Miss: Proxy + Lazy Mirroring
    _log.info('🌐 Proxy Stream: $path');
    final input = ArtifactInput(
      repositoryName: repo,
      namespace: repo,
      packageName: nameOnly,
      version: version,
      path: path,
    );

    final stream = await _downloadArtifactTarballUseCase.executeProxyStream(
      remoteUrl: 'https://registry.npmjs.org/$path',
      input: input,
    );

    return Response.ok(
      stream,
      headers: {'Content-Type': 'application/octet-stream'},
    );
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

        final input = ArtifactInput(
          repositoryName: repo,
          namespace: ns,
          packageName: pkg,
          version: ver,
          path: relativePath,
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

  /// GET /artifacts/:externalId
  /// Busca metadados de um artefato específico via UUID
  Future<Response> getByExternalId(Request request, String externalId) {
    final path = request.url.path;

    return _measure('GET', path, () async {
      final baseUrl = request.requestedUri.origin;

      try {
        final artifact = await _getByIdUseCase.execute(externalId);

        if (artifact == null) {
          return ErrorPresenter.notFound(
            'Artefato não encontrado.',
            path,
            baseUrl,
          );
        }

        return Response.ok(
          jsonEncode(ArtifactPresenter.createArtifact(artifact, baseUrl)),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e, stack) {
        _log.severe('❌ Erro ao buscar por ID: $externalId', e, stack);
        return ErrorPresenter.internalServerError(
          "Erro na busca por ID.",
          path,
          baseUrl,
        );
      }
    });
  }

  /// GET /resolve/:repository/:package/:version
  /// Resolve a localização do artefato (Banco ou Proxy)
  Future<Response> resolve(
    Request request,
    String repositoryName,
    String packageName,
    String version,
  ) {
    final path = request.url.path;

    return _measure('GET', path, () async {
      final baseUrl = request.requestedUri.origin;

      try {
        final artifact = await _getArtifactUseCase.execute(
          repositoryName: repositoryName,
          packageName: packageName,
          version: version,
        );

        if (artifact == null) {
          return ErrorPresenter.notFound(
            'Artefato não encontrado.',
            path,
            baseUrl,
          );
        }

        return ArtifactPresenter.success(artifact);
      } catch (e, stack) {
        _log.severe('❌ Erro na resolução: $packageName@$version', e, stack);
        return ErrorPresenter.internalServerError(
          "Erro na resolução.",
          path,
          baseUrl,
        );
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
        final result = await _proxyPackageMetadataUseCase.execute(
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
