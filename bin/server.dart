import 'dart:io';
import 'package:logging/logging.dart';
import 'package:minio/minio.dart';
import 'package:sambura_core/application/usecase/get_artifact_by_id_usecase.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/api/controller/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/package_controller.dart';
import 'package:sambura_core/infrastructure/repositories/postgres_blob_repository.dart';
import 'package:sambura_core/infrastructure/repositories/silo_blob_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:sambura_core/config/env.dart';
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';
import 'package:sambura_core/infrastructure/repositories/postgres_repository_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres_artifact_repository.dart';
import 'package:sambura_core/infrastructure/repositories/postgres_package_repository.dart';
import 'package:sambura_core/infrastructure/services/npm_proxy_service.dart';
import 'package:sambura_core/application/usecase/get_artifact_usecase.dart';
import 'package:sambura_core/application/usecase/create_artifact_usecase.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/repository_controller.dart';
import 'package:sambura_core/infrastructure/api/routes.dart';

void main() async {
  // Inicializa o sistema de logging
  LoggerConfig.initialize(level: Level.ALL);
  final log = LoggerConfig.getLogger('Server');

  log.info('🌊 Iniciando os motores do Samburá...');

  // Carrega as configurações
  final env = Env().load();
  log.info('Configurações carregadas: ${env.dbHost}:${env.dbPort}');

  // Conexão com o Banco de Dados usando o objeto 'env'
  final dbConnector = PostgresConnector(
    env.dbHost,
    env.dbPort,
    env.dbUser,
    env.dbPassword,
    env.dbName,
  );
  log.info(
    'Tentando conexão com Postgres: ${env.dbUser}@${env.dbHost}:${env.dbPort}/${env.dbName}',
  );

  try {
    await dbConnector.connect();
    log.info('Conexão com Postgres estabelecida com sucesso!');
  } catch (e, stackTrace) {
    log.severe(
      'Erro ao conectar com Postgres na porta ${env.dbPort}',
      e,
      stackTrace,
    );
    log.warning('Verifique se o container está rodando');
    return;
  }

  // Configura o cliente do MinIO (Silo)
  final minioClient = Minio(
    endPoint: env.siloHost,
    port: env.siloPort,
    useSSL: false,
    accessKey: env.siloAccessKey,
    secretKey: env.siloSecretKey,
    region: 'us-east-1',
  );

  final bucketName = 'sambura-blobs';

  try {
    final exists = await minioClient.bucketExists(bucketName);
    if (!exists) {
      await minioClient.makeBucket(bucketName, 'us-east-1');
      log.info('Bucket "$bucketName" criado com sucesso no LocalStack');
    } else {
      log.info('Bucket "$bucketName" já existe no LocalStack');
    }
  } catch (e, stackTrace) {
    log.severe('Erro ao gerenciar bucket no LocalStack', e, stackTrace);
  }

  log.info('Inicializando repositórios...');
  final repositoryRepo = PostgresRepositoryRepository(dbConnector);
  final artifactRepo = PostgresArtifactRepository(dbConnector);
  final packageRepo = PostgresPackageRepository(dbConnector);
  final postgresBlobRepo = PostgresBlobRepository(dbConnector);
  final blobRepo = SiloBlobRepository(
    minioClient,
    bucketName,
    postgresBlobRepo,
  );
  log.info('Repositórios inicializados com sucesso');

  // Instanciação dos Serviços Externos
  log.info('Inicializando serviços externos...');
  final npmProxy = NpmProxyService(blobRepo);
  log.info('Serviços externos inicializados');

  // Instanciação dos Casos de Uso (Application)
  log.info('Inicializando casos de uso...');
  final getArtifactUseCase = GetArtifactUseCase(
    artifactRepo,
    packageRepo,
    repositoryRepo,
    npmProxy,
  );

  final getByIdUseCase = GetArtifactByIdUseCase(artifactRepo);

  final createArtifactUseCase = CreateArtifactUsecase(
    artifactRepo,
    packageRepo,
    blobRepo,
  );

  // Instanciação dos Controllers (API)
  final artifactController = ArtifactController(
    createArtifactUseCase,
    getArtifactUseCase,
    getByIdUseCase,
  );

  final repositoryController = RepositoryController(repositoryRepo);

  final packageController = PackageController(packageRepo);

  final blobController = BlobController(blobRepo);

  // Injeta no ApiRouter seguindo a ORDEM do construtor
  final apiRouter = ApiRouter(
    artifactController,
    packageController,
    repositoryController,
    blobController,
  );

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(apiRouter.handler);

  log.info('Controllers configurados com sucesso');

  // Subida do Servidor
  log.info('Iniciando servidor HTTP...');
  final server = await io.serve(handler, InternetAddress.anyIPv4, env.port);
  log.info('🚀 Samburá online em http://${server.address.host}:${server.port}');
  log.info('Sistema pronto para receber requisições');
}
