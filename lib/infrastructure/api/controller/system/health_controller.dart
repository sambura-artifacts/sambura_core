import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/usecase/health/get_server_health_usecase.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class HealthController {
  final GetServerHealthUseCase _getHealthUseCase;
  final Logger _log = LoggerConfig.getLogger('HealthController');

  HealthController(this._getHealthUseCase);

  Router get router {
    final router = Router();

    router.get('/', (Request request) async {
      _log.info('🏥 Health check requested');
      
      final health = await _getHealthUseCase.execute();

      final isHealthy = health['status'] == 'healthy';

      if (isHealthy) {
        _log.info('✅ Health check passed - all services healthy');
      } else {
        _log.warning('⚠️  Health check failed - services: ${health['services']}');
      }

      return Response(
        isHealthy ? 200 : 503,
        body: jsonEncode(health),
        headers: {'content-type': 'application/json'},
      );
    });

    router.get('/liveness', (Request request) {
      _log.fine('💓 Liveness check requested');
      return Response.ok(
        jsonEncode({'status': 'alive'}),
        headers: {'content-type': 'application/json'},
      );
    });

    return router;
  }
}
