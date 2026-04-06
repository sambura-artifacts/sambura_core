import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class NpmControllerGetMetadata {
  final NpmGetPackageMetadataUseCase _npmGetPackageMetadataUsecase;
  final Logger _log = LoggerConfig.getLogger('NpmControllerGetMetadata');

  NpmControllerGetMetadata(this._npmGetPackageMetadataUsecase);

  Future<Response> execute(
    Request request,
    String namespace,
    String packageName,
  ) async {
    try {
      // Executa o Use Case
      final result = await _npmGetPackageMetadataUsecase.execute(
        InfraestructureArtifactInput(
          namespace: namespace,
          packageName: packageName,
          packageManager: 'npm',
        ).sanitize(),
      );

      final headers = {
        'Content-Type': 'application/json',
        'X-Sambura-Cache': result!.isEmpty ? 'HIT' : 'MISS',
        'content-encoding': 'gzip',
      };

      return Response.ok(jsonEncode(result), headers: headers);
    } on InsecureArtifactException catch (e) {
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
        '🚨 Serviço externo indisponível ao processar metadata NPM: $namespace/$packageName',
        e,
        stackTrace,
      );
      return ErrorPresenter.serviceUnavailable(
        e.message,
        request.requestedUri.path,
        AppConfig.baseUrl,
      );
    }
  }
}
