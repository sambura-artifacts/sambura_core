import 'package:shelf/shelf.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/ports/metrics_port.dart';
import 'package:sambura_core/domain/exceptions/domain_exception.dart';
import 'package:sambura_core/domain/exceptions/security_exception.dart';
import 'package:sambura_core/infrastructure/api/presenter/error_presenter.dart';

final _log = LoggerConfig.getLogger('ErrorHandlerMiddleware');

Middleware errorHandler(String baseUrl, MetricsPort metrics) {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (e, stack) {
        final instance = request.requestedUri.path;

        if (e is SecurityException) {
          metrics.recordViolation(e.message);

          _log.severe('🛡️ [SECURITY ALERT] $e | Instance: $instance');
        } else if (e is! DomainException) {
          _log.severe('❌ [INTERNAL ERROR]', e, stack);
        }

        return ErrorPresenter.fromException(e, instance, baseUrl);
      }
    };
  };
}
