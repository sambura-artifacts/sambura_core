import 'package:sambura_core/infrastructure/api/controller/api_key_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/package_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/repository_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/upload_controller.dart';
import 'package:sambura_core/infrastructure/api/middleware/auth_middleware.dart';
import 'package:sambura_core/infrastructure/api/routes/admin_router.dart';
import 'package:sambura_core/infrastructure/api/routes/public_router.dart';
import 'package:sambura_core/infrastructure/services/auth_service.dart';
import 'package:sambura_core/infrastructure/services/hash_service.dart';
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
  final AuthService _authService;
  final ApiKeyRepository _apiKeyRepo;
  final AccountRepository _accountRepo;
  final HashService _hashService;

  MainRouter(
    this._authController,
    this._repositoryController,
    this._packageController,
    this._artifactController,
    this._blobController,
    this._apiKeyController,
    this._uploadController,
    this._authService,
    this._apiKeyRepo,
    this._accountRepo,
    this._hashService,
  );

  Handler get handler {
    final mainRouter = Router();

    // 1. Instancia os módulos que organizam as rotas
    final publicRouter = PublicRouter(
      _authController,
      _artifactController,
      _blobController,
      _authService,
      _apiKeyRepo,
      _accountRepo,
      _hashService,
    );

    final adminRouter = AdminRouter(
      _repositoryController,
      _packageController,
      _artifactController,
      _apiKeyController,
      _uploadController,
    );

    // 2. Pipeline de autenticação
    final authenticatedPipeline = Pipeline().addMiddleware(
      authMiddleware(_accountRepo, _authService, _apiKeyRepo, _hashService),
    );

    // 3. Rotas Públicas (Login, etc)
    mainRouter.mount('/', publicRouter.router.call);

    // 4. Rotas Protegidas
    final protectedRouter = Router();

    // Sub-rotas de Admin
    protectedRouter.mount('/admin', adminRouter.router.call);

    // API de Consumo Privada
    protectedRouter.get(
      '/api/v1/download/<namespace>/<name>/<version>',
      _artifactController.downloadByVersion,
    );
    protectedRouter.get(
      '/api/v1/resolve/<repository>/<package>/<version>',
      _artifactController.resolve,
    );

    mainRouter.mount(
      '/',
      authenticatedPipeline.addHandler(protectedRouter.call),
    );

    return mainRouter.call;
  }
}
