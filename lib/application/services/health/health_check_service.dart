import 'package:sambura_core/application/ports/ports.dart';

class HealthCheckService {
  final List<HealthCheckPort> _adapters;
  final MetricsPort _metrics; // Usa a Interface

  HealthCheckService(this._adapters, this._metrics);

  Future<Map<String, dynamic>> checkAll() async {
    final results = await Future.wait(_adapters.map((c) => c.check()));
    final isAllHealthy = results.every((r) => r.isHealthy);

    // 1. Relata o status geral
    _metrics.reportHealthStatus(isAllHealthy);

    for (var r in results) {
      // 2. Relata cada componente individualmente
      _metrics.reportComponentStatus(r.name, r.isHealthy, r.elapsed);
    }

    return {
      'status': isAllHealthy ? 'HEALTHY' : 'PARTIAL_FAILURE',
      'components': {for (var r in results) r.name: r.toMap()},
    };
  }
}
