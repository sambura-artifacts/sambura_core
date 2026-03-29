import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/application/usecase/usecases.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/base_package_handler.dart';

class NpmHandler extends BasePackageHandler {
  NpmHandler(
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
        log: LoggerConfig.getLogger('NpmHandler'),
        handlerName: 'npm',
      );

  @override
  Uri buildRemoteUrl(ArtifactInput input) {
    final unscopedName = input.packageName.split('/').last;
    final baseUrl = input.remoteUrl.endsWith('/')
        ? input.remoteUrl.substring(0, input.remoteUrl.length - 1)
        : input.remoteUrl;

    log.info(
      'Construindo URL remota para NPM: ${input.remoteUrl}/${input.namespace}/${input.packageName}@${input.version}',
    );

    final remoteUrl = Uri.parse(
      '$baseUrl/${input.packageName}/-/$unscopedName-${input.version}.tgz',
    );
    return remoteUrl;
  }
}
