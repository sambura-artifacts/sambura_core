import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/application/usecase/health/get_server_health_usecase.dart';

/// Gerencia endpoints relacionados ao estado e metadados do servidor.
class SystemController {
  final GetServerHealthUseCase _getHealthUseCase;

  SystemController(this._getHealthUseCase);

  Router get router {
    final router = Router();

    // GET /api/v1/system/health
    router.get('/health', _healthHandler);

    // GET /api/v1/system/liveness
    router.get('/liveness', _livenessHandler);

    return router;
  }

  Future<Response> _healthHandler(Request request) async {
    final health = await _getHealthUseCase.execute();
    final isHealthy = health['status'] == 'healthy';

    return Response(
      isHealthy ? 200 : 503,
      body: jsonEncode(health),
      headers: {'content-type': 'application/json'},
    );
  }

  Response _livenessHandler(Request request) {
    return Response.ok(
      jsonEncode({'status': 'alive'}),
      headers: {'content-type': 'application/json'},
    );
  }
}
