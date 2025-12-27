import 'package:logging/logging.dart';
import 'package:sambura_core/config/env.dart';
import 'package:http/http.dart' as http;

// Ports
import 'package:sambura_core/application/ports/auth_port.dart';
import 'package:sambura_core/application/ports/cache_port.dart';
import 'package:sambura_core/application/ports/hash_port.dart';
import 'package:sambura_core/application/ports/metrics_port.dart';

// Services (Application)
import 'package:sambura_core/application/services/health/health_check_service.dart';
import 'package:sambura_core/application/services/auth/auth_service.dart';

// Adapters (Infrastructure)
import 'package:sambura_core/infrastructure/adapters/auth/local_auth_adapter.dart';
import 'package:sambura_core/infrastructure/adapters/auth/bcrypt_hash_adapter.dart';
import 'package:sambura_core/infrastructure/adapters/cache/redis_adapter.dart';
import 'package:sambura_core/infrastructure/adapters/health/redis_healt_check.dart';
import 'package:sambura_core/infrastructure/adapters/http/http_client_adapter.dart';
import 'package:sambura_core/infrastructure/adapters/observability/prometheus_metrics_adapter.dart';
import 'package:sambura_core/infrastructure/adapters/storage/minio_storage_adapter.dart';
import 'package:sambura_core/infrastructure/adapters/health/blob_storage_health_check.dart';
import 'package:sambura_core/infrastructure/adapters/health/postgres_health_check.dart';
import 'package:sambura_core/infrastructure/api/controller/system/metrics_controller.dart';

// Database & Repositories
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';
import 'package:sambura_core/infrastructure/repositories/postgres/postgres_blob_repository.dart';
import 'package:sambura_core/infrastructure/repositories/blob/silo_blob_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres/postgres_repository_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres/postgres_artifact_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres/postgres_package_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres/postgres_account_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres/postgres_api_key_repository.dart';

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
import 'package:sambura_core/application/usecase/artifact/download_artifact_tarball_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/check_artifact_exists_usecase.dart';
import 'package:sambura_core/application/usecase/package/get_package_metadata_usecase.dart';
import 'package:sambura_core/application/usecase/package/proxy_package_metadata_usecase.dart';
import 'package:sambura_core/application/usecase/health/get_server_health_usecase.dart';

// Controllers & Routes
import 'package:sambura_core/infrastructure/api/controller/artifact/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/package_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/repository_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/auth/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/admin/api_key_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/upload_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/system/system_controller.dart';
import 'package:sambura_core/infrastructure/api/routes/admin_router.dart';
import 'package:sambura_core/infrastructure/api/routes/artifact_router.dart';
import 'package:sambura_core/infrastructure/api/routes/protected_router.dart';
import 'package:sambura_core/infrastructure/api/routes/public_router.dart';
import 'package:sambura_core/infrastructure/services/secrets/vault_service.dart';
import 'package:sambura_core/infrastructure/proxies/npm_proxy.dart';

class DependencyInjection {
  late final AuthController authController;
  late final ApiKeyController apiKeyController;
  late final ArtifactController artifactController;
  late final RepositoryController repositoryController;
  late final PackageController packageController;
  late final BlobController blobController;
  late final UploadController uploadController;
  late final SystemController systemController;

  late final PublicRouter publicRouter;
  late final AdminRouter adminRouter;
  late final ProtectedRouter protectedRouter;
  late final ArtifactRouter artifactRouter;

  late final AuthPort authProvider;
  late final HashPort hashPort;
  late final CachePort cachePort;
  late final MetricsPort metricsPort;

  late final PostgresApiKeyRepository apiKeyRepository;
  late final PostgresAccountRepository accountRepository;
  late final VaultService vaultService;
  late final CreateAccountUsecase createAccountUsecase;

  static Future<DependencyInjection> init(EnvConfig env) async {
    final di = DependencyInjection();
    final log = Logger('DI');

    log.info('🚀 Iniciando Injeção de Dependências...');

    // 1. INFRAESTRUTURA BASE (SECRETS & DATABASE)
    di.vaultService = VaultService(env.vaultUrl, env.vaultToken);
    final authSecrets = await di.vaultService.getSecrets(env.vaultAuthPath);
    final dbSecrets = await di.vaultService.getSecrets(env.vaultDatabasePath);

    if (dbSecrets.isEmpty || authSecrets.isEmpty) {
      throw Exception('Vault secrets missing');
    }

    final postgresConnector = PostgresConnector(
      env.dbHost,
      env.dbPort,
      env.dbUser,
      env.dbPassword,
      env.dbName,
    );
    await postgresConnector.connect();

    final redisAdapter = RedisAdapter(host: env.redisHost, port: env.redisPort);
    await redisAdapter.connect();
    di.cachePort = redisAdapter;

    final minioAdapter = MinioStorageAdapter(
      endPoint: env.siloHost,
      port: env.siloPort,
      accessKey: env.siloAccessKey,
      secretKey: env.siloSecretKey,
      useSSL: env.siloUseSSL,
      bucket: env.bucketName,
    );

    // 2. OBSERVABILITY (METRICS)
    PrometheusMetricsAdapter.initialize();
    di.metricsPort = PrometheusMetricsAdapter();

    // 3. ADAPTERS & REPOSITORIES
    di.hashPort = BcryptHashAdapter(authSecrets['pepper']);
    di.accountRepository = PostgresAccountRepository(postgresConnector);
    di.apiKeyRepository = PostgresApiKeyRepository(postgresConnector);

    final repositoryRepo = PostgresRepositoryRepository(postgresConnector);
    final artifactRepo = PostgresArtifactRepository(postgresConnector);
    final packageRepo = PostgresPackageRepository(postgresConnector);
    final postgresBlobRepo = PostgresBlobRepository(postgresConnector);
    final siloBlobRepo = SiloBlobRepository(minioAdapter, postgresBlobRepo);

    // 4. HEALTH CHECKS CONFIG
    final healthChecks = [
      PostgresHealthCheck(postgresConnector),
      RedisHealthCheck(redisAdapter),
      BlobStorageHealthCheck(env.bucketName, minioAdapter),
    ];

    // 5. APPLICATION SERVICES
    final authInternal = AuthService(authSecrets['jwt_secret']);
    di.authProvider = LocalAuthAdapter(authInternal);

    final healthService = HealthCheckService(healthChecks, di.metricsPort);

    // 6. PROXIES & HTTP
    final client = http.Client();
    final httpClient = HttpClientAdapter(client);
    final npmProxy = NpmProxy(siloBlobRepo, packageRepo);

    // 7. USE CASES
    di.createAccountUsecase = CreateAccountUsecase(
      di.accountRepository,
      di.hashPort,
    );
    final loginUsecase = LoginUsecase(
      di.accountRepository,
      di.hashPort,
      authSecrets['jwt_secret'],
    );
    final healthUseCase = GetServerHealthUseCase(healthService);

    final generateApiKeyUsecase = GenerateApiKeyUsecase(di.apiKeyRepository);
    final listApiKeysUsecase = ListApiKeysUsecase(di.apiKeyRepository);
    final revokeApiKeyUsecase = RevokeApiKeyUsecase(
      di.apiKeyRepository,
      di.accountRepository,
    );

    final proxyPackageMetadataUseCase = ProxyPackageMetadataUseCase(httpClient);
    final getArtifactUseCase = GetArtifactUseCase(
      artifactRepo,
      packageRepo,
      repositoryRepo,
      npmProxy,
    );
    final getMetadataUseCase = GetPackageMetadataUseCase(artifactRepo);
    final getArtifactDownloadStreamUsecase = GetArtifactDownloadStreamUsecase(
      artifactRepo,
      siloBlobRepo,
      redisAdapter,
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
    final checkArtifactExistsUseCase = CheckArtifactExistsUseCase(artifactRepo);

    final downloadArtifactTarballUseCase = DownloadArtifactTarballUseCase(
      httpClient,
      createArtifactUseCase,
      getArtifactDownloadStreamUsecase,
      di.cachePort,
      di.metricsPort,
    );

    // 8. CONTROLLERS
    di.authController = AuthController(di.createAccountUsecase, loginUsecase);
    di.apiKeyController = ApiKeyController(
      generateApiKeyUsecase,
      listApiKeysUsecase,
      revokeApiKeyUsecase,
    );
    di.repositoryController = RepositoryController(repositoryRepo);
    di.packageController = PackageController(
      packageRepo,
      getMetadataUseCase,
      proxyPackageMetadataUseCase,
    );
    di.blobController = BlobController(siloBlobRepo);
    di.uploadController = UploadController(
      uploadArtifactUsecase,
      checkArtifactExistsUseCase,
    );
    di.artifactController = ArtifactController(
      createArtifactUseCase,
      getArtifactUseCase,
      GetArtifactByIdUseCase(artifactRepo),
      getArtifactDownloadStreamUsecase,
      generateApiKeyUsecase,
      proxyPackageMetadataUseCase,
      downloadArtifactTarballUseCase,
      di.metricsPort,
    );
    di.systemController = SystemController(healthUseCase);

    // 9. ROUTERS
    di.publicRouter = PublicRouter(
      env,
      di.authController,
      di.artifactController,
      di.blobController,
      di.systemController,
      MetricsController(),
      di.apiKeyRepository,
      di.accountRepository,
      di.authProvider,
      di.cachePort,
      di.metricsPort, // Injetando a porta de métricas no router para o middleware
    );

    di.adminRouter = AdminRouter(di.apiKeyController);
    di.artifactRouter = ArtifactRouter(
      di.repositoryController,
      di.packageController,
      di.artifactController,
      di.uploadController,
    );
    di.protectedRouter = ProtectedRouter(
      di.authController,
      di.adminRouter,
      di.artifactRouter,
    );

    log.info('✅ Injeção de Dependências concluída com sucesso.');
    return di;
  }
}
