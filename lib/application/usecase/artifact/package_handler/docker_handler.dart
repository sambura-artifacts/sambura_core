import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/application/usecase/usecases.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/base_package_handler.dart';

class DockerHandler extends BasePackageHandler {
  DockerHandler(
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
        log: LoggerConfig.getLogger('DockerHandler'),
        handlerName: 'docker',
      );
  @override
  Uri buildRemoteUrl(ArtifactInput input) {
    final packageName = input.packageName;
    final digest = input.metadata['digest'];
    // TODO: A URL base (docker.io) deve vir das configurações do repositório
    return Uri.parse(
      'https://registry-1.docker.io/v2/library/$packageName/blobs/$digest',
    );
  }
}
