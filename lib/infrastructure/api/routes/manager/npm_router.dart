import 'package:shelf_router/shelf_router.dart';
import 'package:logging/logging.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class NpmRouter {
  final NpmControllerDownloadTarball _npmControllerDownloadTarball;
  final NpmControllerGetMetadata _npmControllerGetMetadata;
  final NpmControllerSecurityAdvisoryConsulting
  _npmControllerSecurityAdvisoryConsulting;
  final Logger _log = LoggerConfig.getLogger('NpmRouter');
  NpmRouter(
    this._npmControllerDownloadTarball,
    this._npmControllerGetMetadata,
    this._npmControllerSecurityAdvisoryConsulting,
  );

  Router get router {
    final router = Router();

    _log.info('Registrando rotas NPM Proxy');

    // 4. NPM Proxy Routes
    router.get(
      '/<repo>/<package|.*>/-/<filename>',
      _npmControllerDownloadTarball.execute,
    );

    router.get('/<repo>/<packageName|.*>', _npmControllerGetMetadata.execute);

    router.post(
      '/<repo>/-/npm/v1/security/advisories/bulk',
      _npmControllerSecurityAdvisoryConsulting.execute,
    );

    return router;
  }
}
