import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:sambura_core/application/usecase/api_key/generate_api_key_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/get_artifact_by_id_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/get_artifact_download_stream_usecase.dart';
import 'package:sambura_core/application/usecase/package/get_package_metadata_usecase.dart';
import 'package:sambura_core/application/usecase/package/proxy_package_metadata_usecase.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/entities/account_entity.dart';
import 'package:sambura_core/domain/exceptions/domain_exception.dart';
import 'package:sambura_core/infrastructure/api/helpers/package_path_parser.dart';
import 'package:sambura_core/infrastructure/api/presenter/artifact/npm_packument_presenter.dart';
import 'package:shelf/shelf.dart';
import 'package:sambura_core/application/usecase/artifact/get_artifact_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/create_artifact_usecase.dart';
import 'package:sambura_core/infrastructure/api/presenter/artifact/artifact_presenter.dart';
import 'package:sambura_core/infrastructure/api/presenter/error_presenter.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';
import 'package:shelf_router/shelf_router.dart';

class ArtifactController {
  final CreateArtifactUsecase _createArtifactUseCase;
  final GetArtifactUseCase _getArtifactUseCase;
  final GetArtifactByIdUseCase _getByIdUseCase;
  final GetArtifactDownloadStreamUsecase _getArtifactDownloadStreamUsecase;
  final GenerateApiKeyUsecase _generateApiKeyUsecase;
  final GetPackageMetadataUseCase _getPackageMetadataUseCase;
  final ProxyPackageMetadataUseCase _proxyPackageMetadataUseCase;
  final Logger _log = LoggerConfig.getLogger('ArtifactController');

  // No construtor, a gente recebe os UseCases.
  // O repositório a gente deixa pros UseCases resolverem.
  ArtifactController(
    this._createArtifactUseCase,
    this._getArtifactUseCase,
    this._getByIdUseCase,
    this._getArtifactDownloadStreamUsecase,
    this._generateApiKeyUsecase,
    this._getPackageMetadataUseCase,
    this._proxyPackageMetadataUseCase,
  );

  /// POST /:repository/:namespace/:package/:version
  Future<Response> upload(
    Request request,
    String repositoryName,
    String namespace,
    String packageName,
    String version,
  ) async {
    final baseUrl = request.requestedUri.origin;
    final instance = request.url.path;

    _log.info(
      'Upload iniciado: repo=$repositoryName, pkg=$packageName, version=$version',
    );

    try {
      // Pega o resto do path (ex: o nome do arquivo .tgz)
      final path = request.url.pathSegments.skip(3).join('/');
      final byteStream = request.read();

      final input = ArtifactInput(
        repositoryName: repositoryName,
        namespace: namespace,
        packageName: packageName,
        version: version,
        path: path,
      );

      _log.fine('Executando usecase de criação de artefato');
      final artifact = await _createArtifactUseCase.execute(input, byteStream);

      if (artifact == null) {
        return ErrorPresenter.notFound(
          'Repositório ou Artefato não encontrado.',
          instance,
          baseUrl,
        );
      }

      _log.info(
        'Upload concluído com sucesso: artifact_id=${artifact.externalId}',
      );
      return ArtifactPresenter.createArtifact(artifact, baseUrl);
    } on RepositoryNotFoundException catch (e) {
      _log.warning(e.message);
      return ErrorPresenter.notFound(e.message, instance, baseUrl);
    } on ArtifactNotFoundException catch (e) {
      _log.warning(e.message);
      return ErrorPresenter.notFound(e.message, instance, baseUrl);
    } catch (e, stack) {
      _log.severe(
        'Erro ao processar upload de $packageName@$version',
        e,
        stack,
      );
      return ErrorPresenter.internalServerError(
        "Ocorreu uma falha inesperada ao processar o upload do artefato.",
        instance,
        baseUrl,
        error: e,
        stack: stack,
      );
    }
  }

  /// GET /:repository/:package/:version
  /// Aqui é onde o Proxy brilha através do GetArtifactUseCase
  Future<Response> getArtifactByRepositoryAndPackageAndVersion(
    Request request,
    String repositoryName,
    String packageName,
    String version,
  ) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final baseUrl = request.requestedUri.origin;
    final instance = request.url.path;

    _log.info(
      '[REQ:$requestId] GET /$repositoryName/$packageName/$version - Buscando artefato',
    );

    try {
      final artifact = await _getArtifactUseCase.execute(
        repositoryName: repositoryName,
        packageName: packageName,
        version: version,
      );

      if (artifact == null) {
        _log.warning(
          '[REQ:$requestId] ✗ Artefato não encontrado: $packageName@$version no repo $repositoryName',
        );
        return ErrorPresenter.notFound(
          'O pacote $packageName na versão $version não foi encontrado no repositório $repositoryName.',
          instance,
          baseUrl,
        );
      }

      _log.info(
        '[REQ:$requestId] ✓ Artefato encontrado: id=${artifact.externalId}',
      );
      return ArtifactPresenter.createArtifact(artifact, baseUrl);
    } catch (e, stack) {
      _log.severe(
        '[REQ:$requestId] ✗ Erro ao resolver artefato $packageName@$version',
        e,
        stack,
      );
      return ErrorPresenter.internalServerError(
        "Erro ao resolver artefato.",
        instance,
        baseUrl,
        error: e,
        stack: stack,
      );
    }
  }

  /// GET /<repositoryName>/<packageName>/<version>
  /// Este método "resolve" a localização do artefato (Banco ou Proxy NPM)
  Future<Response> resolve(
    Request request,
    String repositoryName,
    String packageName,
    String version,
  ) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final baseUrl = request.requestedUri.origin;
    final instance = request.url.path;

    _log.info(
      '[REQ:$requestId] Resolvendo localização de $repositoryName/$packageName@$version',
    );

    try {
      _log.fine('[REQ:$requestId] Executando usecase de resolução');
      final artifact = await _getArtifactUseCase.execute(
        repositoryName: repositoryName,
        packageName: packageName,
        version: version,
      );

      if (artifact == null) {
        _log.warning(
          '[REQ:$requestId] ✗ Artefato não encontrado após resolução: $packageName@$version',
        );
        return ErrorPresenter.notFound(
          'O pacote $packageName na versão $version não foi encontrado no repositório $repositoryName.',
          instance,
          baseUrl,
        );
      }

      _log.info(
        '[REQ:$requestId] ✓ Resolução bem-sucedida: artifact_id=${artifact.externalId}',
      );
      return ArtifactPresenter.success(artifact);
    } on RepositoryNotFoundException catch (e) {
      _log.warning('[REQ:$requestId] ✗ ${e.message}');
      return ErrorPresenter.notFound(e.message, instance, baseUrl);
    } on ArtifactNotFoundException catch (e) {
      _log.warning('[REQ:$requestId] ✗ ${e.message}');
      return ErrorPresenter.notFound(e.message, instance, baseUrl);
    } catch (e, stack) {
      _log.severe(
        '[REQ:$requestId] ✗ Erro crítico ao resolver artefato $packageName@$version',
        e,
        stack,
      );
      return ErrorPresenter.internalServerError(
        "Erro ao processar a resolução do artefato.",
        instance,
        baseUrl,
        error: e,
        stack: stack,
      );
    }
  }

  /// GET /artifacts/<externalId>
  /// Busca os metadados de um artefato específico pelo seu UUID
  Future<Response> getByExternalId(Request request, String externalId) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final baseUrl = request.requestedUri.origin;

    _log.info(
      '[REQ:$requestId] GET /artifacts/$externalId - Buscando artefato por ID',
    );

    try {
      final artifact = await _getByIdUseCase.execute(externalId);

      if (artifact == null) {
        _log.warning(
          '[REQ:$requestId] ✗ Artefato não encontrado para ID: $externalId',
        );
        return ErrorPresenter.notFound(
          'Artefato não encontrado.',
          request.url.path,
          baseUrl,
        );
      }

      _log.info(
        '[REQ:$requestId] ✓ Artefato encontrado: ${artifact.packageName}@${artifact.version}',
      );
      return Response.ok(
        ArtifactPresenter.createArtifact(artifact, baseUrl),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _log.severe(
        '[REQ:$requestId] ✗ Erro ao buscar artefato por ID: $externalId',
        e,
        stackTrace,
      );
      return ErrorPresenter.internalServerError(
        "Erro ao buscar",
        request.url.path,
        baseUrl,
      );
    }
  }

  Future<Response> downloadByVersion(
    Request request,
    String namespace,
    String name,
    String version,
  ) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final baseUrl = request.requestedUri.origin;

    _log.info(
      '[REQ:$requestId] GET /download/$namespace/$name/$version - Iniciando download',
    );

    try {
      final result = await _getArtifactDownloadStreamUsecase.execute(
        namespace: namespace,
        name: name,
        version: version,
      );

      if (result == null) {
        _log.warning(
          '[REQ:$requestId] ✗ Artefato não localizado: $namespace/$name@$version',
        );
        return ErrorPresenter.notFound(
          "Artefato não localizado.",
          request.url.path,
          baseUrl,
        );
      }

      _log.info(
        '[REQ:$requestId] ✓ Download iniciado: $name@$version, ${result.blob.sizeBytes} bytes',
      );
      return Response.ok(
        result.stream,
        headers: {
          'Content-Type': result.blob.mimeType,
          'Content-Length': result.blob.sizeBytes.toString(),
          'Content-Disposition':
              'attachment; filename="${name}-${version}.tgz"',
        },
      );
    } catch (e, stack) {
      _log.severe(
        '[REQ:$requestId] ✗ Erro no controller de download',
        e,
        stack,
      );
      return ErrorPresenter.internalServerError(
        "Erro interno.",
        request.url.path,
        baseUrl,
      );
    }
  }

  Future<Response> generateApiKey(Request request) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final user = request.context['user'] as AccountEntity;

    _log.info(
      '[REQ:$requestId] POST /generate-api-key - Usuário: ${user.username}, Role: ${user.role}',
    );

    // Só admin ou o próprio dono pode gerar (Regra de negócio)
    if (user.role != 'admin') {
      _log.warning(
        '[REQ:$requestId] ✗ Acesso negado para gerar API key: usuário não é admin',
      );
      return Response.forbidden(
        jsonEncode({'error': 'Só o admin pode gerar ApiKey!'}),
      );
    }

    try {
      final payload = jsonDecode(await request.readAsString());
      final keyName = payload['name'] ?? 'default-key';

      _log.info('[REQ:$requestId] Gerando API key com nome: $keyName');

      // Chama o Usecase que a gente acabou de criar
      final result = await _generateApiKeyUsecase.execute(
        accountId: user.id!,
        keyName: keyName,
      );

      _log.info(
        '[REQ:$requestId] ✓ API key gerada com sucesso: ${result.name}',
      );
      return Response.ok(
        jsonEncode({
          'message': 'Guarda isso num lugar seguro!',
          'api_key': result.plainKey,
          'name': result.name,
        }),
      );
    } catch (e, stack) {
      _log.severe('[REQ:$requestId] ✗ Erro ao gerar API key', e, stack);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro ao gerar chave: $e'}),
      );
    }
  }

  Future<Response> getPackageMetadata(Request request) async {
    final repo = request.params['repo'];
    final packageName = request.params['name'];

    if (packageName == null || repo == null) {
      _log.severe('❌ Parâmetros nulos no Router');
      return Response.internalServerError();
    }

    // 1. Tratamento de Binário (.tgz)
    if (packageName.endsWith('.tgz')) {
      final nameOnly = PackagePathParser.extractName(packageName);
      final version = PackagePathParser.extractVersion(packageName);

      final downloadResult = await _getArtifactDownloadStreamUsecase.execute(
        namespace: repo,
        name: nameOnly,
        version: version,
      );

      if (downloadResult != null) {
        _log.info('📦 Cache Hit Silo: $nameOnly@$version');
        return Response.ok(
          downloadResult.stream, // ✅ Extrai o stream real
          headers: {'Content-Type': 'application/octet-stream'},
        );
      }
    }

    // 2. Proxy (Metadata JSON ou Binário não cacheado)
    final result = await _proxyPackageMetadataUseCase.execute(
      packageName,
      repoName: repo,
    );

    if (result == null) return Response.notFound('Pacote não encontrado');

    // 3. Persistência se for binário novo
    if (packageName.endsWith('.tgz') && result is Uint8List) {
      // Não damos await para o dev não esperar o banco salvar
      _persistProxyResult(
        repo,
        packageName,
        result,
      ).catchError((e) => _log.severe(e));

      return Response.ok(
        result,
        headers: {'Content-Type': 'application/octet-stream'},
      );
    }

    // 4. Retorno de Metadata (JSON)
    return Response.ok(
      result is Map ? jsonEncode(result) : result,
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<void> _persistProxyResult(
    String repo,
    String path,
    Uint8List bytes,
  ) async {
    try {
      final name = PackagePathParser.extractName(path);
      final version = PackagePathParser.extractVersion(path);
      final fileName = path.split('/').last;

      _log.info('💾 Persistindo no Silo: $name@$version');

      final input = ArtifactInput(
        repositoryName: repo,
        packageName: name,
        version: version,
        filename: fileName,
        namespace: repo,
        path: '$name/-/$fileName',
      );

      final stream = Stream.value(bytes);

      await _createArtifactUseCase.execute(input, stream);

      _log.info('✅ Cache salvo com sucesso para $fileName');
    } catch (e) {
      _log.severe('❌ Erro ao persistir cache do proxy', e);
    }
  }
}
