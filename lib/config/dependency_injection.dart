import 'package:logging/logging.dart';
import 'package:sambura_core/application/ports/auth_port.dart';
import 'package:sambura_core/application/ports/cache_port.dart';
import 'package:sambura_core/config/env.dart';
import 'package:sambura_core/infrastructure/adapters/auth/local_auth_adapter.dart';
import 'package:sambura_core/infrastructure/adapters/cache/redis_adapter.dart';

// Adapters & Infra
import 'package:sambura_core/infrastructure/adapters/http/http_client_adapter.dart';
import 'package:sambura_core/infrastructure/adapters/storage/minio_storage_adapter.dart';
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';
import 'package:sambura_core/infrastructure/services/secrets/vault_service.dart';
import 'package:sambura_core/infrastructure/services/auth/hash_service.dart';
import 'package:sambura_core/infrastructure/services/auth/auth_service.dart';
import 'package:sambura_core/infrastructure/proxies/npm_proxy.dart';

// Repositories
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
import 'package:sambura_core/application/usecase/package/get_package_metadata_usecase.dart';
import 'package:sambura_core/application/usecase/package/proxy_package_metadata_usecase.dart';
import 'package:sambura_core/application/usecase/health/get_server_health_usecase.dart';

// Controllers
import 'package:sambura_core/infrastructure/api/controller/artifact/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/package_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/repository_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/auth/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/admin/api_key_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/upload_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/system/system_controller.dart';

class DependencyInjection {
  // Controllers (Expostos para o Router)
  late final AuthController authController;
  late final ApiKeyController apiKeyController;
  late final ArtifactController artifactController;
  late final RepositoryController repositoryController;
  late final PackageController packageController;
  late final BlobController blobController;
  late final UploadController uploadController;
  late final SystemController systemController;

  // Services/Repos (Necessários para o Router ou Middlewares)
  late final AuthPort authProvider;
  late final PostgresApiKeyRepository apiKeyRepository;
  late final PostgresAccountRepository accountRepository;
  late final HashService hashService;
  late final CachePort cachePort;

  // Use Case/Services (Necessários para o Bootstrap)
  late final CreateAccountUsecase createAccountUsecase;
  late final VaultService vaultService;

  static Future<DependencyInjection> init(EnvConfig env) async {
    final di = DependencyInjection();
    final log = Logger('DI');

    // 1. INFRAESTRUTURA & SECRETS
    final vaultService = VaultService(env.vaultUrl, env.vaultToken);

    di.vaultService = vaultService;

    final authSecrets = await vaultService.getSecrets(env.vaultAuthPath);
    final dbSecrets = await vaultService.getSecrets(env.vaultDatabasePath);

    if (dbSecrets.isEmpty || authSecrets.isEmpty) {
      log.severe('❌ Falha crítica: Segredos não encontrados!');
      throw Exception('Vault secrets missing');
    }

    final dbConnector = PostgresConnector(
      env.dbHost,
      env.dbPort,
      env.dbUser,
      env.dbPassword,
      env.dbName,
    );
    await dbConnector.connect();

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

    // 2. REPOSITORIES
    di.accountRepository = PostgresAccountRepository(dbConnector);
    di.apiKeyRepository = PostgresApiKeyRepository(dbConnector);
    final repositoryRepo = PostgresRepositoryRepository(dbConnector);
    final artifactRepo = PostgresArtifactRepository(dbConnector);
    final packageRepo = PostgresPackageRepository(dbConnector);
    final postgresBlobRepo = PostgresBlobRepository(dbConnector);
    final siloBlobRepo = SiloBlobRepository(minioAdapter, postgresBlobRepo);

    // 3. SERVICES & PROXIES

    di.hashService = HashService(authSecrets['pepper']);
    final npmProxy = NpmProxy(siloBlobRepo);
    final httpClient = HttpClientAdapter();
    final authInternal = AuthService(authSecrets['jwt_secret']);
    di.authProvider = LocalAuthAdapter(authInternal);

    // 4. USE CASES
    final loginUsecase = LoginUsecase(
      di.accountRepository,
      di.hashService,
      authSecrets['jwt_secret'],
    );
    final createAccountUsecase = CreateAccountUsecase(
      di.accountRepository,
      di.hashService,
    );

    di.createAccountUsecase = createAccountUsecase;

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
    final healthUseCase = GetServerHealthUseCase(artifactRepo, minioAdapter);

    // 5. CONTROLLERS
    di.authController = AuthController(createAccountUsecase, loginUsecase);
    di.apiKeyController = ApiKeyController(
      generateApiKeyUsecase,
      listApiKeysUsecase,
      revokeApiKeyUsecase,
    );
    di.repositoryController = RepositoryController(repositoryRepo);
    di.packageController = PackageController(packageRepo, getMetadataUseCase);
    di.blobController = BlobController(siloBlobRepo);
    di.uploadController = UploadController(uploadArtifactUsecase);
    di.systemController = SystemController(healthUseCase);

    di.artifactController = ArtifactController(
      createArtifactUseCase,
      getArtifactUseCase,
      GetArtifactByIdUseCase(artifactRepo),
      getArtifactDownloadStreamUsecase,
      generateApiKeyUsecase,
      proxyPackageMetadataUseCase,
    );

    return di;
  }
}
