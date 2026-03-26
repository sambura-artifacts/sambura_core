import 'package:mocktail/mocktail.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/config/env.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/artifact_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/blob_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/auth/auth_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/system/system_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/system/metrics_controller.dart';
import 'package:sambura_core/infrastructure/api/routes/package_manager_router.dart';
import 'package:sambura_core/infrastructure/api/routes/public_router.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:test/test.dart';

class MockPackageManagerRouter extends Mock implements PackageManagerRouter {}

class MockAuthController extends Mock implements AuthController {}

class MockArtifactController extends Mock implements ArtifactController {}

class MockBlobController extends Mock implements BlobController {}

class MockSystemController extends Mock implements SystemController {}

class MockMetricsController extends Mock implements MetricsController {}

class MockApiKeyRepository extends Mock implements ApiKeyRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockAuthPort extends Mock implements AuthPort {}

class MockCachePort extends Mock implements CachePort {}

class MockMetricsPort extends Mock implements MetricsPort {}

void main() {
  setUpAll(() {
    registerFallbackValue(Request('GET', Uri.parse('http://localhost/')));
  });

  test(
    'PublicRouter exposes /npm route directly and legacy /packages/npm works',
    () async {
      final packageManagerRouter = MockPackageManagerRouter();
      final pmRouter = Router();
      pmRouter.get('/npm/<repo>/<package|.*>', (
        Request request,
        String repo,
        String package,
      ) {
        return Response.ok('OK');
      });

      when(() => packageManagerRouter.router).thenReturn(pmRouter);

      final mockAuthController = MockAuthController();
      final mockArtifactController = MockArtifactController();
      final mockBlobController = MockBlobController();
      final mockSystemController = MockSystemController();
      final mockMetricsController = MockMetricsController();
      final mockApiKeyRepo = MockApiKeyRepository();
      final mockAccountRepo = MockAccountRepository();
      final mockAuthPort = MockAuthPort();
      final mockCache = MockCachePort();
      final mockMetricsPort = MockMetricsPort();

      when(
        () => mockSystemController.router,
      ).thenReturn(Router()..get('/health', (_) => Response.ok('healthy')));
      when(
        () => mockMetricsController.getMetrics(any()),
      ).thenAnswer((_) async => Response.ok('metrics'));

      final env = EnvConfig(
        environment: Environment.development,
        appName: 'sambura-core',
        port: 8080,
        publicOrigin: 'http://localhost:8080',
        dbHost: 'localhost',
        dbPort: 5432,
        dbUser: 'sambura',
        dbPassword: 'sambura',
        dbName: 'sambura',
        redisHost: 'localhost',
        redisPort: 6379,
        rabbitmqHost: 'localhost',
        rabbitmqPort: 5672,
        rabbitmqUser: 'guest',
        rabbitmqPass: 'guest',
        siloHost: 'localhost',
        siloPort: 9000,
        siloAccessKey: 'minio',
        siloSecretKey: 'minio123',
        siloUseSSL: false,
        bucketName: 'sambura',
        keycloakUrl: 'http://localhost/auth',
        keycloakRealm: 'sambura',
        keycloakClientId: 'sambura',
        vaultUrl: 'http://localhost:8200',
        vaultToken: 'token',
        vaultAuthPath: 'auth',
        vaultDatabasePath: 'database',
        logFilePath: '/tmp/test.log',
        logLevel: 'info',
      );

      final publicRouter = PublicRouter(
        env,
        packageManagerRouter,
        mockAuthController,
        mockArtifactController,
        mockBlobController,
        mockSystemController,
        mockApiKeyRepo,
        mockAccountRepo,
        mockAuthPort,
        mockCache,
        mockMetricsPort,
      );

      final handler = publicRouter.router;

      final response = await handler.call(
        Request('GET', Uri.parse('http://localhost/npm/public/express')),
      );
      expect(response.statusCode, equals(200));

      final responseLegacy = await handler.call(
        Request(
          'GET',
          Uri.parse('http://localhost/packages/npm/public/express'),
        ),
      );
      expect(responseLegacy.statusCode, equals(200));
    },
  );
}
