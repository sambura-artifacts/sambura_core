import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class DependencyInjection {
  late final AuthController authController;
  late final ApiKeyController apiKeyController;
  late final ArtifactController artifactController;
  late final PackageController packageController;
  late final NpmControllerDownloadTarball npmControllerDownloadTarball;
  late final NpmControllerGetMetadata npmControllerGetMetadata;
  late final NpmControllerSecurityAdvisoryConsulting
  npmControllerSecurityAdvisoryConsulting;
  late final NamespaceController namespaceController;
  late final BlobController blobController;
  late final UploadController uploadController;
  late final SystemController systemController;

  late final PublicRouter publicRouter;
  late final AdminRouter adminRouter;
  late final ProtectedRouter protectedRouter;
  late final ArtifactRouter artifactRouter;
  late final PackageManagerRouter packageManagerRouter;

  late final AuthPort authProvider;
  late final HashPort hashPort;
  late final CachePort cachePort;
  late final MetricsPort metricsPort;

  late final PostgresApiKeyRepository apiKeyRepository;
  late final PostgresAccountRepository accountRepository;
  late final NamespaceRepository namespaceRepository;
  late final VaultService vaultService;
  late final CreateAccountUsecase createAccountUsecase;

  void configureNpmControllers({
    required NpmDownloadArtifactUsecase npmDownloadArtifactUsecase,
    required NpmGetPackageMetadataUseCase npmGetPackageMetadataUseCase,
    required NpmSecurityAdvisoryConsultingUsecase
    npmSecurityAdvisoryConsultingUsecase,
  }) {
    npmControllerDownloadTarball = NpmControllerDownloadTarball(
      npmDownloadArtifactUsecase,
    );
    npmControllerGetMetadata = NpmControllerGetMetadata(
      npmGetPackageMetadataUseCase,
    );
    npmControllerSecurityAdvisoryConsulting =
        NpmControllerSecurityAdvisoryConsulting(
          npmSecurityAdvisoryConsultingUsecase,
        );
  }

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

    final namespaceRepository = PostgresNamespaceRepository(postgresConnector);
    final artifactRepository = PostgresArtifactRepository(postgresConnector);
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

    final generateApiKeyUsecase = GenerateApiKeyUsecase(di.apiKeyRepository);
    final listApiKeysUsecase = ListApiKeysUsecase(di.apiKeyRepository);
    final revokeApiKeyUsecase = RevokeApiKeyUsecase(
      di.apiKeyRepository,
      di.accountRepository,
    );

    final proxyPackageMetadataUseCase = NpmProxyPackageMetadataUseCase(
      httpClient,
    );

    final getArtifactDownloadStreamUsecase = GetArtifactDownloadStreamUsecase(
      artifactRepository,
      siloBlobRepo,
      redisAdapter,
    );
    final uploadArtifactUsecase = UploadArtifactUsecase(
      artifactRepository,
      packageRepo,
      namespaceRepository,
      siloBlobRepo,
    );
    final createArtifactUseCase = CreateArtifactUsecase(
      artifactRepository,
      packageRepo,
      siloBlobRepo,
      namespaceRepository,
    );
    final checkArtifactExistsUseCase = CheckArtifactExistsUseCase(
      artifactRepository,
    );

    final packageHandlerFactory = PackageHandlerFactory(
      httpClient,
      createArtifactUseCase,
      getArtifactDownloadStreamUsecase,
      namespaceRepository,
      di.cachePort,
      di.metricsPort,
    );

    final npmDownloadAndProxyArtifactUsecase = NpmDownloadArtifactUsecase(
      getArtifactDownloadStreamUsecase,
      namespaceRepository,
      packageHandlerFactory,
      DependencyTrackAdapter(httpClient, env.dtrackApiUrl, env.dtrackApiKey),
      di.cachePort,
    );

    // 8. CONTROLLERS
    di.authController = AuthController(
      di.createAccountUsecase,
      loginUsecase,
      di.authProvider,
    );

    di.configureNpmControllers(
      npmDownloadArtifactUsecase: npmDownloadAndProxyArtifactUsecase,
      npmGetPackageMetadataUseCase: NpmGetPackageMetadataUseCase(
        artifactRepository,
        namespaceRepository,
        httpClient,
      ),
      npmSecurityAdvisoryConsultingUsecase:
          NpmSecurityAdvisoryConsultingUsecase(httpClient),
    );

    di.apiKeyController = ApiKeyController(
      generateApiKeyUsecase,
      listApiKeysUsecase,
      revokeApiKeyUsecase,
    );

    di.packageController = PackageController(
      packageRepo,
      NpmGetPackageMetadataUseCase(
        artifactRepository,
        namespaceRepository,
        httpClient,
      ),
      NpmProxyPackageMetadataUseCase(httpClient),
    );

    di.namespaceController = NamespaceController(namespaceRepository);

    di.blobController = BlobController(siloBlobRepo);
    di.uploadController = UploadController(
      uploadArtifactUsecase,
      checkArtifactExistsUseCase,
    );
    di.artifactController = ArtifactController(
      createArtifactUseCase,
      getArtifactDownloadStreamUsecase,
      proxyPackageMetadataUseCase,
      generateApiKeyUsecase,
      di.metricsPort,
    );

    di.systemController = SystemController(
      GetServerHealthUseCase(healthService),
      MetricsController(),
    );

    // 9. ROUTERS
    di.packageManagerRouter = PackageManagerRouter(
      NpmRouter(
        di.npmControllerDownloadTarball,
        di.npmControllerGetMetadata,
        di.npmControllerSecurityAdvisoryConsulting,
      ),
    );

    di.publicRouter = PublicRouter(
      di.packageManagerRouter,
      di.authController,
      di.systemController,
    );

    di.adminRouter = AdminRouter(di.apiKeyController, di.namespaceController);
    di.artifactRouter = ArtifactRouter(
      di.packageController,
      di.artifactController,
      di.blobController,
    );
    di.protectedRouter = ProtectedRouter(
      di.authController,
      di.adminRouter,
      di.artifactRouter,
      di.packageManagerRouter,
    );

    log.info('✅ Injeção de Dependências concluída com sucesso.');
    return di;
  }
}
