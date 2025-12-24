import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/api/controller/admin/api_key_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/auth/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/package_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/repository_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/upload_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/system/health_controller.dart';
import 'package:sambura_core/infrastructure/api/middleware/auth_middleware.dart';
import 'package:sambura_core/infrastructure/api/routes/admin_router.dart';
import 'package:sambura_core/infrastructure/api/routes/public_router.dart';
import 'package:sambura_core/infrastructure/services/auth/auth_service.dart';
import 'package:sambura_core/infrastructure/services/auth/hash_service.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class MainRouter {
  final AuthController _authController;
  final RepositoryController _repositoryController;
  final PackageController _packageController;
  final ArtifactController _artifactController;
  final BlobController _blobController;
  final ApiKeyController _apiKeyController;
  final UploadController _uploadController;
  final HealthController _healthController;
  final AuthService _authService;
  final ApiKeyRepository _apiKeyRepo;
  final AccountRepository _accountRepo;
  final HashService _hashService;

  final Logger _log = LoggerConfig.getLogger('MainRouter');

  MainRouter(
    this._authController,
    this._repositoryController,
    this._packageController,
    this._artifactController,
    this._blobController,
    this._apiKeyController,
    this._uploadController,
    this._healthController,
    this._authService,
    this._apiKeyRepo,
    this._accountRepo,
    this._hashService,
  );

  Handler get handler {
    final mainRouter = Router();

    // 1. Definição do Router Público (Registro, Login, Health)
    final publicRouter = PublicRouter(
      _authController,
      _artifactController,
      _blobController,
      _authService,
      _apiKeyRepo,
      _accountRepo,
      _hashService,
    );

    // 2. Definição do Router Protegido (Admin, Upload, Gestão)
    final adminRouter = AdminRouter(
      _repositoryController,
      _packageController,
      _artifactController,
      _apiKeyController,
      _uploadController,
    );

    final protectedRouter = Router();

    // Sub-rotas do Admin
    protectedRouter.mount('/admin', adminRouter.router.call);

    // Busca de pacotes no NPM (npm search)
    // Encaminha a consulta para o registro oficial e retorna resultados filtrados
    protectedRouter.get('/npm/<repo>/-/v1/search', (Request req) {
      _log.fine('🎯 Rota casada: SEARCH | Path: ${req.url.path}');
      return _artifactController.searchPackages(req);
    });
    protectedRouter.get('/npm/<repo>/<name|.*>', (Request req) {
      _log.fine('📦 Rota casada: METADATA | Path: ${req.url.path}');
      return _artifactController.getPackageMetadata(req);
    });

    // --- 🔵 SEÇÃO GESTÃO E DOWNLOAD ---

    protectedRouter.get(
      '/download/<repo>/<name|.*>/<version>',
      _artifactController.downloadByVersion,
    );

    protectedRouter.get(
      '/resolve/<repository>/<package>/<version>',
      _artifactController.resolve,
    );

    // Suporte a Upload/Publish
    protectedRouter.put('/upload', _uploadController.handle);
    protectedRouter.post('/upload', _uploadController.handle);
    protectedRouter.put('/npm/<repo>/<name|.*>', _uploadController.handle);

    // Rotas Protegidas sob Middleware de Autenticação (JWT ou API Key)
    final authenticatedHandler = Pipeline()
        .addMiddleware(
          authMiddleware(_accountRepo, _authService, _apiKeyRepo, _hashService),
        )
        .addHandler(protectedRouter.call);

    _log.info('🚀 Montando API em /api/v1');
    mainRouter.mount('/api/v1', authenticatedHandler);
    mainRouter.mount('/api/v1/public', publicRouter.router.call);
    mainRouter.mount('/health', _healthController.router.call);

    return mainRouter.call;
  }
}
