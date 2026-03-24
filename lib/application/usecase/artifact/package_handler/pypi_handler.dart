import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/application/usecase/usecases.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/base_package_handler.dart';

class PypiHandler extends BasePackageHandler {
  PypiHandler(
    HttpClientPort httpClient,
    CreateArtifactUsecase createArtifact,
    GetArtifactDownloadStreamUsecase getArtifactDownloadStreamUsecase,
    CachePort cache,
    MetricsPort metrics,
  ) : super(
        httpClient: httpClient,
        createArtifact: createArtifact,
        getArtifactDownloadStreamUsecase: getArtifactDownloadStreamUsecase,
        cache: cache,
        metrics: metrics,
        log: LoggerConfig.getLogger('PypiHandler'),
        handlerName: 'pypi',
      );

  @override
  Uri buildRemoteUrl(ArtifactInput input) {
    // A URL do PyPI (pypi.org) não segue um padrão tão direto quanto o Maven
    // A URL real do download vem dos metadados "simple"
    // Ex: https://files.pythonhosted.org/packages/....
    // Por enquanto, vamos assumir uma URL base que precisa ser complementada
    final fullPath = input.metadata['fullPath'] as String;
    // TODO: A URL base deve vir das configurações do repositório
    return Uri.parse('https://files.pythonhosted.org/packages/$fullPath');
  }
}
