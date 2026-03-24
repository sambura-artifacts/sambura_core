import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client/format.dart' as format;
import 'package:shelf/shelf.dart';

class MetricsController {
  Future<Response> getMetrics(Request request) async {
    try {
      final buffer = StringBuffer();

      final metrics = await CollectorRegistry.defaultRegistry
          .collectMetricFamilySamples();

      format.write004(buffer, metrics);

      return Response.ok(
        buffer.toString(),
        headers: {
          'Content-Type': 'text/plain; version=0.0.4',
          'Cache-Control': 'no-cache',
        },
      );
    } catch (e) {
      return Response.internalServerError(body: 'Erro ao coletar métricas: $e');
    }
  }
}
