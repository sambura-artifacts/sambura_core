import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/domain/barrel.dart';

class NpmHandler extends NpmBasePackageHandler {
  NpmHandler(
    HttpClientPort httpClient,
    CreateArtifactUsecase createArtifact,
    GetArtifactDownloadStreamUsecase getArtifactDownloadStreamUsecase,
    NamespaceRepository namespaceRepository,
    CachePort cache,
    MetricsPort metrics,
  ) : super(
        httpClient: httpClient,
        createArtifact: createArtifact,
        getArtifactDownloadStreamUsecase: getArtifactDownloadStreamUsecase,
        namespaceRepository: namespaceRepository,
        cache: cache,
        metrics: metrics,
        log: LoggerConfig.getLogger('NpmHandler'),
        handlerName: 'npm',
      );

  @override
  Uri buildRemoteUrl(ApplicationArtifactInput input) {
    final unscopedName = input.packageName.split('/').last;

    log.info(
      'Construindo URL remota para NPM: ${input.remoteUrl}/${input.namespace}/${input.packageName}@${input.version}',
    );

    final remoteUrl = Uri.parse(
      '${input.remoteUrl}/${input.packageName}/-/$unscopedName-${input.version}.tgz',
    );
    return remoteUrl;
  }
}
