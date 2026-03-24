import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/application/usecase/usecases.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/base_package_handler.dart';

class NugetHandler extends BasePackageHandler {
  NugetHandler(
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
        log: LoggerConfig.getLogger('NugetHandler'),
        handlerName: 'nuget',
      );

  @override
  Uri buildRemoteUrl(ArtifactInput input) {
    final packageName = input.packageName.toLowerCase();
    final version = input.version.toLowerCase();
    final filename = input.fileName?.toLowerCase();
    // TODO: A URL base deve vir das configurações do repositório
    return Uri.parse(
      'https://api.nuget.org/v3-flatcontainer/$packageName/$version/$filename',
    );
  }
}
