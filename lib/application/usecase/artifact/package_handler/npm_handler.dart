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
    // TODO: move to Repository settings
    final remoteUrl = Uri.parse(
      'https://registry.npmjs.org/${input.packageName}/-/${input.packageName}-${input.version}.tgz',
    );
    return remoteUrl;
  }
}
