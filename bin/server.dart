import 'dart:io';
import 'package:logging/logging.dart';
import 'package:minio/minio.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

// Configurações
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/config/env.dart';

// Infraestrutura - Banco e Conectores
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';

// Repositories
import 'package:sambura_core/infrastructure/repositories/postgres/postgres_blob_repository.dart';
import 'package:sambura_core/infrastructure/repositories/blob/silo_blob_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres/postgres_repository_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres/postgres_artifact_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres/postgres_package_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres/postgres_account_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres/postgres_api_key_repository.dart';

// Services
import 'package:sambura_core/infrastructure/services/cache/redis_service.dart';
import 'package:sambura_core/infrastructure/services/secrets/vault_service.dart';
import 'package:sambura_core/infrastructure/services/auth/hash_service.dart';
import 'package:sambura_core/infrastructure/services/auth/auth_service.dart';
import 'package:sambura_core/infrastructure/proxies/npm_proxy.dart';

// UseCases
import 'package:sambura_core/application/usecase/account/create_account_usecase.dart';
import 'package:sambura_core/application/usecase/auth/login_usecase.dart';
import 'package:sambura_core/application/usecase/api_key/generate_api_key_usecase.dart';
import 'package:sambura_core/application/usecase/api_key/list_api_keys_usecase.dart';
import 'package:sambura_core/application/usecase/api_key/revoke_api_key_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/create_artifact_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/get_artifact_by_id_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/get_artifact_download_stream_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/get_artifact_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/upload_artifact_usecase.dart';
import 'package:sambura_core/application/usecase/package/get_package_metadata_usecase.dart';

// Controllers
import 'package:sambura_core/infrastructure/api/controller/artifact/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/package_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/repository_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/auth/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/admin/api_key_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/upload_controller.dart';

// Rotas
import 'package:sambura_core/infrastructure/api/routes/main_router.dart';

void main() async {
  // Logger
  LoggerConfig.initialize(level: Level.ALL);
  final log = LoggerConfig.getLogger('Server');

  // Config
  final env = Env().load();

  final vaultService = VaultService(env.vaultUrl, env.vaultToken);

  final dbSecrets = await vaultService.getSecrets('sambura/database');
  final authSecrets = await vaultService.getSecrets('sambura/auth');

  if (dbSecrets.isEmpty || authSecrets.isEmpty) {
    log.severe('❌ Falha crítica: Segredos não encontrados no Vault!');
    return;
  }

  // Database
  final dbConnector = PostgresConnector(
    env.dbHost,
    env.dbPort,
    env.dbUser,
    env.dbPassword,
    env.dbName,
  );
  await dbConnector.connect();

  // Redis
  final redisService = RedisService(host: env.redisHost, port: env.redisPort);
  await redisService.connect();

  // MinIO
  final minioClient = Minio(
    endPoint: env.siloHost,
    port: env.siloPort,
    useSSL: false,
    accessKey: env.siloAccessKey,
    secretKey: env.siloSecretKey,
  );

  // Repositories
  final accountRepo = PostgresAccountRepository(dbConnector);
  final apiKeyRepo = PostgresApiKeyRepository(dbConnector);
  final repositoryRepo = PostgresRepositoryRepository(dbConnector);
  final artifactRepo = PostgresArtifactRepository(dbConnector);
  final packageRepo = PostgresPackageRepository(dbConnector);
  final postgresBlobRepo = PostgresBlobRepository(dbConnector);
  final siloBlobRepo = SiloBlobRepository(
    minioClient,
    env.bucketName,
    postgresBlobRepo,
  );

  // Services
  final hashService = HashService(authSecrets['pepper']);
  final authService = AuthService(authSecrets['jwt_secret']);
  final npmProxy = NpmProxy(siloBlobRepo);

  // UseCases
  final loginUsecase = LoginUsecase(
    accountRepo,
    hashService,
    authSecrets['jwt_secret'],
  );
  final createAccountUsecase = CreateAccountUsecase(accountRepo, hashService);
  final generateApiKeyUsecase = GenerateApiKeyUsecase(apiKeyRepo);
  final listApiKeysUsecase = ListApiKeysUsecase(apiKeyRepo);
  final revokeApiKeyUsecase = RevokeApiKeyUsecase(apiKeyRepo, accountRepo);
  final getPackageMetadataUseCase = GetPackageMetadataUseCase(artifactRepo);

  final getArtifactUseCase = GetArtifactUseCase(
    artifactRepo,
    packageRepo,
    repositoryRepo,
    npmProxy,
  );
  final getArtifactDownloadStreamUsecase = GetArtifactDownloadStreamUsecase(
    artifactRepo,
    siloBlobRepo,
    redisService,
  );
  final uploadArtifactUsecase = UploadArtifactUsecase(
    artifactRepo,
    packageRepo,
    repositoryRepo,
    siloBlobRepo,
  );

  final createArtifactUseCase = CreateArtifactUsecase(
    artifactRepo,
    packageRepo,
    siloBlobRepo,
    repositoryRepo,
  );

  final authController = AuthController(createAccountUsecase, loginUsecase);
  final apiKeyController = ApiKeyController(
    generateApiKeyUsecase,
    listApiKeysUsecase,
    revokeApiKeyUsecase,
  );

  final artifactController = ArtifactController(
    createArtifactUseCase,
    getArtifactUseCase,
    GetArtifactByIdUseCase(artifactRepo),
    getArtifactDownloadStreamUsecase,
    generateApiKeyUsecase,
    getPackageMetadataUseCase,
  );

  final repositoryController = RepositoryController(repositoryRepo);
  final packageController = PackageController(packageRepo);
  final blobController = BlobController(siloBlobRepo);
  final uploadController = UploadController(uploadArtifactUsecase);

  // Router
  final mainRouter = MainRouter(
    authController,
    repositoryController,
    packageController,
    artifactController,
    blobController,
    apiKeyController,
    uploadController,
    authService,
    apiKeyRepo,
    accountRepo,
    hashService,
  );

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(mainRouter.handler);

  final server = await io.serve(handler, InternetAddress.anyIPv4, env.port);
  log.info('🚀 SAMBURÁ ONLINE | http://${server.address.host}:${server.port}');
}
