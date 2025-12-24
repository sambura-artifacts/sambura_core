import 'dart:convert';
import 'package:sambura_core/application/usecase/health/get_server_health_usecase.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class HealthController {
  final GetServerHealthUseCase _getHealthUseCase;

  HealthController(this._getHealthUseCase);

  Router get router {
    final router = Router();

    router.get('/', (Request request) async {
      final health = await _getHealthUseCase.execute();

      final isHealthy = health['status'] == 'healthy';

      return Response(
        isHealthy ? 200 : 503,
        body: jsonEncode(health),
        headers: {'content-type': 'application/json'},
      );
    });

    router.get('/liveness', (Request request) {
      return Response.ok(
        jsonEncode({'status': 'alive'}),
        headers: {'content-type': 'application/json'},
      );
    });

    return router;
  }
}
