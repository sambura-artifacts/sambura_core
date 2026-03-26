import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/app_config.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/exceptions/exceptions.dart';
import 'package:sambura_core/application/usecase/artifact/download_npm_artifact_usecase.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';
import 'package:sambura_core/infrastructure/api/presenter/error_presenter.dart';

class NpmController {
  final DownloadNpmArtifactUsecase _downloadAndProxyArtifactUsecase;
  final Logger _log = LoggerConfig.getLogger('NpmController');

  NpmController(this._downloadAndProxyArtifactUsecase);

  Future<Response> downloadTarball(
    Request request,
    String repo,
    String package,
    String filename,
  ) async {
    try {
      // Extrair versão do filename: filename = '${unscopedName}-${version}.tgz'
      // ex: gen-mapping-0.3.3.tgz -> version=0.3.3
      // Para scoped packages: @scope/package -> filename usa apenas 'package'
      _log.fine('📥 Parsing filename: package=$package, filename=$filename');

      // Extrair nome unscoped (para @scope/name, pega 'name')
      final unscopedName = package.split('/').last;
      _log.fine('✓ Nome unscoped extraído: $unscopedName');

      // Extrair versão usando o nome unscoped
      if (!filename.startsWith('$unscopedName-')) {
        throw FormatException(
          'Filename inválido: esperado "$unscopedName-X.X.X.tgz", recebido "$filename"',
        );
      }

      final version = filename
          .substring(unscopedName.length + 1)
          .replaceAll('.tgz', '');

      _log.fine('✓ Versão extraída: $version');

      final input = ArtifactInput(
        namespace: repo,
        packageName: package, // pode ter @scope/pkg
        version: version,
        fileName: filename,
      );

      _log.info(
        '🌐 [NPM Download] Requisição recebida: $repo/${input.packageName}@${input.version}',
      );

      final stream = await _downloadAndProxyArtifactUsecase.execute(input);

      if (stream == null) {
        _log.warning(
          '⚠️ Stream é nulo para $repo/${input.packageName}@${input.version}',
        );
        return Response.notFound('Artefato não encontrado');
      }

      _log.info(
        '✅ Stream obtido com sucesso para ${input.packageName}@${input.version}',
      );
      return Response.ok(stream);
    } on ExternalServiceUnavailableException catch (e, stackTrace) {
      _log.severe(
        '🚨 Serviço externo indisponível ao processar download NPM: $repo/$package/-/$filename',
        e,
        stackTrace,
      );
      return ErrorPresenter.serviceUnavailable(
        e.message,
        request.requestedUri.path,
        AppConfig.baseUrl,
      );
    } catch (e, stackTrace) {
      _log.severe(
        '❌ Erro ao processar download NPM: $repo/$package/-/$filename',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<Response> getPackageMetadata(
    Request request,
    String repo,
    String packageName,
  ) async {
    // TODO: Implementar busca de metadados do NPM (package.json)
    return Response(501, body: 'Busca de metadados NPM não implementada');
  }
}
