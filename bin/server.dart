import 'dart:io';
import 'package:sambura_core/infrastructure/bootstrap/bootstrap_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:logging/logging.dart';

// Configs
import 'package:sambura_core/config/env.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/config/dependency_injection.dart';

// Router
import 'package:sambura_core/infrastructure/api/routes/main_router.dart';

void main() async {
  final env = Env().load();

  LoggerConfig.initialize(level: Level.ALL, filePath: env.logFilePath);
  final log = Logger('Server');

  try {
    log.info('🔧 Inicializando dependências...');
    final di = await DependencyInjection.init(env);

    // 2. Executa o Bootstrap
    final bootstrap = BootstrapService(
      di.accountRepository,
      di.createAccountUsecase,
      di.vaultService,
    );

    await bootstrap.run();

    final mainRouter = MainRouter(
      di.authController,
      di.systemController,
      di.authProvider,
      di.accountRepository,
      di.apiKeyRepository,
      di.cachePort,
    );

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(mainRouter.handler);

    final server = await io.serve(handler, InternetAddress.anyIPv4, env.port);

    log.info(
      '🚀 SAMBURÁ ONLINE | http://${server.address.host}:${server.port}',
    );
    log.info('🌍 Environment: ${env.environment.name}');
  } catch (e, stack) {
    log.severe('💥 Erro fatal durante o boot:', e, stack);
    exit(1);
  }
}
