import 'dart:io';
import 'package:logging/logging.dart';
import 'package:minio/minio.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

// Configurações e Infra
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/config/env.dart';
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';

// Repositórios
import 'package:sambura_core/infrastructure/repositories/postgres_blob_repository.dart';
import 'package:sambura_core/infrastructure/repositories/silo_blob_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres_repository_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres_artifact_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres_package_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres_account_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres_api_key_repository.dart';

// Serviços e Segurança
import 'package:sambura_core/infrastructure/services/redis_service.dart';
import 'package:sambura_core/infrastructure/services/vault_service.dart';
import 'package:sambura_core/infrastructure/services/hash_service.dart';
import 'package:sambura_core/infrastructure/services/auth_service.dart';
import 'package:sambura_core/infrastructure/proxies/npm_proxy.dart';

// Casos de Uso
import 'package:sambura_core/application/usecase/get_artifact_by_id_usecase.dart';
import 'package:sambura_core/application/usecase/get_artifact_download_stream_usecase.dart';
import 'package:sambura_core/application/usecase/get_artifact_usecase.dart';
import 'package:sambura_core/application/usecase/create_artifact_usecase.dart';
import 'package:sambura_core/application/usecase/login_usecase.dart';
import 'package:sambura_core/application/usecase/create_account_usecase.dart';
import 'package:sambura_core/application/usecase/generate_api_key_usecase.dart';

// Controllers e Rotas
import 'package:sambura_core/infrastructure/api/controller/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/package_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/repository_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/api_key_controller.dart';
import 'package:sambura_core/infrastructure/api/routes/main_router.dart';

void main() async {
  LoggerConfig.initialize(level: Level.ALL);
  final log = LoggerConfig.getLogger('Server');

  log.info('🌊 Iniciando os motores do Samburá...');
  final env = Env().load();

  // 1. Vault e Segredos (A base de tudo)
  final vault = VaultService(
    endpoint: Platform.environment['VAULT_ADDR'] ?? 'http://localhost:8200',
    token: Platform.environment['VAULT_TOKEN'] ?? 'root_token_sambura',
  );

  log.info('🔐 Buscando segredos no cofre...');
  final dbSecrets = await vault.getSecrets('sambura/database');
  final authSecrets = await vault.getSecrets('sambura/auth');

  if (dbSecrets.isEmpty || authSecrets.isEmpty) {
    log.severe('❌ Falha crítica: Segredos não encontrados no Vault!');
    return;
  }

  // 2. Infraestrutura (DB, Storage, Cache)
  final dbConnector = PostgresConnector(
    env.dbHost,
    env.dbPort,
    env.dbUser,
    dbSecrets['password'],
    env.dbName,
  );
  await dbConnector.connect();

  final minioClient = Minio(
    endPoint: env.siloHost,
    port: env.siloPort,
    useSSL: false,
    accessKey: env.siloAccessKey,
    secretKey: env.siloSecretKey,
  );

  final redisService = RedisService(
    host: Platform.environment['REDIS_HOST'] ?? 'localhost',
    port: int.parse(Platform.environment['REDIS_PORT'] ?? '6379'),
  );
  await redisService.connect();

  // 3. Repositórios e Serviços de Segurança
  final accountRepo = PostgresAccountRepository(dbConnector);
  final apiKeyRepo = PostgresApiKeyRepository(dbConnector);
  final hashService = HashService(authSecrets['pepper']);
  final authService = AuthService(authSecrets['jwt_secret']);

  final repositoryRepo = PostgresRepositoryRepository(dbConnector);
  final artifactRepo = PostgresArtifactRepository(dbConnector);
  final packageRepo = PostgresPackageRepository(dbConnector);
  final postgresBlobRepo = PostgresBlobRepository(dbConnector);
  final siloBlobRepo = SiloBlobRepository(
    minioClient,
    env.bucketName,
    postgresBlobRepo,
  );

  // 4. Casos de Uso
  final loginUsecase = LoginUsecase(
    accountRepo,
    hashService,
    authSecrets['jwt_secret'],
  );
  final createAccountUsecase = CreateAccountUsecase(accountRepo, hashService);
  final generateApiKeyUsecase = GenerateApiKeyUsecase(apiKeyRepo, hashService);

  final npmProxy = NpmProxy(siloBlobRepo);
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
  final createArtifactUseCase = CreateArtifactUsecase(
    artifactRepo,
    packageRepo,
    siloBlobRepo,
  );

  // 5. Controllers
  final authController = AuthController(createAccountUsecase, loginUsecase);
  final apiKeyController = ApiKeyController(generateApiKeyUsecase, apiKeyRepo);
  final artifactController = ArtifactController(
    createArtifactUseCase,
    getArtifactUseCase,
    GetArtifactByIdUseCase(artifactRepo),
    getArtifactDownloadStreamUsecase,
    generateApiKeyUsecase,
  );
  final repositoryController = RepositoryController(repositoryRepo);
  final packageController = PackageController(packageRepo);
  final blobController = BlobController(siloBlobRepo);

  // 6. Router Principal (Com os 10 argumentos na régua)
  final mainRouter = MainRouter(
    authController,
    repositoryController,
    packageController,
    artifactController,
    blobController,
    apiKeyController,
    authService,
    apiKeyRepo,
    accountRepo,
    hashService,
  );

  // 7. Start do Servidor
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(mainRouter.handler);

  final server = await io.serve(handler, InternetAddress.anyIPv4, env.port);
  log.info('🚀 SAMBURÁ ONLINE | http://${server.address.host}:${server.port}');
}
