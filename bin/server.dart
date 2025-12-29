import 'dart:async';
import 'dart:io';
import 'package:sambura_core/infrastructure/shared/bootstrap/bootstrap_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:logging/logging.dart';

import 'package:sambura_core/config/config.dart';

import 'package:sambura_core/infrastructure/shared/api/routes/routes.dart';

void main() async {
  final env = Env().load();

  LoggerConfig.initialize(level: Level.ALL, filePath: env.logFilePath);
  final log = Logger('Server');

  try {
    log.info('🔧 Inicializando dependências...');
    final di = await DependencyInjection.init(env);

    final bootstrap = BootstrapService(
      di.accountRepository,
      di.createAccountUsecase,
      di.vaultService,
    );

    await bootstrap.run();

    final mainRouter = MainRouter(
      env,
      di.publicRouter,
      di.protectedRouter,
      di.accountRepository,
      di.apiKeyRepository,
      di.authProvider,
      di.cachePort,
      di.metricsPort,
    );

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(mainRouter.handler);

    final server = await io.serve(handler, InternetAddress.anyIPv4, env.port);

    log.info(
      '🚀 SAMBURÁ ONLINE | http://${server.address.host}:${server.port}',
    );
    log.info('🌍 Environment: ${env.environment.name}');

    Timer.periodic(Duration(seconds: 30), (timer) async {
      try {
        await di.systemController.refreshMetrics();
      } catch (e) {
        print('Polling de métricas falhou: $e');
      }
    });
  } catch (e, stack) {
    log.severe('💥 Erro fatal durante o boot:', e, stack);
    exit(1);
  }
}
