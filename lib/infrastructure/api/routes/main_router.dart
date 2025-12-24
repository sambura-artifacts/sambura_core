import 'package:sambura_core/infrastructure/api/controller/admin/api_key_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/auth/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/package_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/repository_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/upload_controller.dart';
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

    // 1. Definição dos Routers Secundários
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

    // 2. Pipeline de Autenticação para Rotas Protegidas
    final authenticatedPipeline = Pipeline().addMiddleware(
      authMiddleware(_accountRepo, _authService, _apiKeyRepo, _hashService),
    );

    // --- ROTAS PÚBLICAS / NPM ---
    // Montamos o publicRouter na raiz ou prefixo /api/v1
    mainRouter.mount('/api/v1', publicRouter.router.call);

    // --- ROTAS PROTEGIDAS (Admin / Download) ---
    final protectedRouter = Router();
    protectedRouter.mount('/admin', adminRouter.router.call);

    protectedRouter.get(
      '/download/<repo>/<name|.*>/<version>',
      _artifactController.downloadByVersion,
    );

    protectedRouter.get(
      '/resolve/<repository>/<package>/<version>',
      _artifactController.resolve,
    );

    protectedRouter.post('/upload', _uploadController.handle);

    // Monta tudo que é protegido sob o pipeline de auth
    mainRouter.mount(
      '/api/v1',
      authenticatedPipeline.addHandler(protectedRouter.call),
    );

    return mainRouter.call;
  }
}
