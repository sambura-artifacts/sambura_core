import 'package:shelf/shelf.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/shared/api/error_presenter.dart';
import 'package:sambura_core/application/shared/ports/ports.dart';
import 'package:sambura_core/domain/exceptions/exceptions.dart';

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
