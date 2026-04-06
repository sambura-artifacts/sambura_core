import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class NpmControllerDownloadTarball {
  final NpmDownloadArtifactUsecase _npmDownloadArtifactUsecase;
  final Logger _log = LoggerConfig.getLogger('NpmController');

  NpmControllerDownloadTarball(this._npmDownloadArtifactUsecase);

  Future<Response> execute(
    Request request,
    String repo,
    String package,
    String filename,
  ) async {
    try {
      _log.fine('📥 Parsing filename: package=$package, filename=$filename');

      final input = InfraestructureArtifactInput(
        namespace: repo,
        packageName: package,
        version: _extractVersionFromFilename(package, filename),
        fileName: filename,
      ).sanitize();

      _log.info(
        '🌐 [NPM Download] Requisição recebida: $repo/${input.packageName}@${input.version}',
      );

      final stream = await _npmDownloadArtifactUsecase.execute(input);

      if (stream == null) {
        _log.warning(
          '⚠️ Stream é nulo para $repo/${input.packageName}@${input.version}',
        );
        return Response.notFound('Artefato não encontrado');
      }

      _log.info(
        '✅ Stream obtido com sucesso para ${input.packageName}@${input.version}',
      );

      return ArtifactPresenter.returnTarballStream(stream, input.version!);
    } on InsecureArtifactException catch (e) {
      _log.severe(
        '⚠️ Artefato inseguro detectado ao processar download NPM: $repo/$package/-/$filename',
      );
      return ErrorPresenter.forbidden(
        jsonEncode({
          "error": "Politicas de segurança (Samburá)",
          "message": e.message,
        }),
        request.requestedUri.path,
        AppConfig.baseUrl,
      );
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
      return ErrorPresenter.fromException(
        e,
        request.requestedUri.path,
        AppConfig.baseUrl,
      );
    }
  }

  String _extractVersionFromFilename(String packageName, String filename) {
    try {
      // 1. Remove a extensão .tgz
      String nameWithVersion = filename.replaceAll('.tgz', '');

      // 2. O NPM segue o padrão: {package-name}-{version}
      // Se o pacote for scoped (@babel/core), o filename vira core-1.0.0.tgz
      // Então removemos o prefixo do pacote (apenas a parte após a última barra se for scoped)
      String cleanPackageName = packageName.contains('/')
          ? packageName.split('/').last
          : packageName;

      // A lógica mágica: remove o nome do pacote e o hífen seguinte
      // O que sobrar é a versão, não importa quantos hifens ela tenha
      if (nameWithVersion.startsWith('$cleanPackageName-')) {
        return nameWithVersion.substring(cleanPackageName.length + 1);
      }

      throw FormatException('Filename não segue o padrão esperado!');
    } catch (e) {
      throw FormatException('Erro ao extrair versão de $filename: $e');
    }
  }
}
