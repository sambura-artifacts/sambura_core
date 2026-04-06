import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class NpmControllerSecurityAdvisoryConsulting {
  final NpmSecurityAdvisoryConsultingUsecase
  _npmSecurityAdvisoryConsultingUsecase;
  final Logger _log = LoggerConfig.getLogger(
    'NpmSecurityAdvisoryConsultingController',
  );

  NpmControllerSecurityAdvisoryConsulting(
    this._npmSecurityAdvisoryConsultingUsecase,
  );

  Future<Response> execute(Request request, String repo) async {
    try {
      _log.info(
        'Requisição de análise de segurança recebida para repositório $repo',
      );

      final body = await request.read().expand((bit) => bit).toList();
      final bytes = await _npmSecurityAdvisoryConsultingUsecase.execute(
        request.headers,
        body,
      );

      return Response.ok(bytes, headers: request.headers);
    } catch (e, stackTrace) {
      _log.severe(
        'Erro ao processar a requisição de análise de segurança',
        e,
        stackTrace,
      );
      return ErrorPresenter.internalServerError(
        'Erro ao processar a requisição',
        '/$repo/-/npm/v1/security/advisories/bulk',
        AppConfig.baseUrl,
      );
    }
  }
}
