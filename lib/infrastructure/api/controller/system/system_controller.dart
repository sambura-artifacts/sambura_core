import 'dart:convert';
import 'package:sambura_core/infrastructure/api/controller/system/metrics_controller.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/application/usecase/health/get_server_health_usecase.dart';

class SystemController {
  final GetServerHealthUseCase _getHealthUseCase;
  final MetricsController _metricsController;

  SystemController(this._getHealthUseCase, this._metricsController);

  Router get router {
    final router = Router();

    // GET /api/v1/system/health
    router.get('/health', _healthHandler);
    router.get('/metrics', _metricsController.getMetrics);

    return router;
  }

  Future<Response> _healthHandler(Request request) async {
    try {
      final healthReport = await _getHealthUseCase.execute();

      final isHealthy = healthReport['status'] == 'HEALTHY';

      return Response(
        isHealthy ? 200 : 503,
        body: jsonEncode(healthReport),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'status': 'error', 'message': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<void> refreshMetrics() async {
    await _getHealthUseCase.execute();
  }
}
