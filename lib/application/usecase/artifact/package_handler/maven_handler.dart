import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/application/usecase/usecases.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/base_package_handler.dart';

class MavenHandler extends BasePackageHandler {
  MavenHandler(
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
        log: LoggerConfig.getLogger('MavenHandler'),
        handlerName: 'maven',
      );

  @override
  Uri buildRemoteUrl(ArtifactInput input) {
    final groupId = input.metadata['groupId'] as String;
    final artifactId = input.metadata['artifactId'] as String;
    final version = input.version;
    final filename = input.fileName;

    final groupPath = groupId.replaceAll('.', '/');

    // TODO: A URL base deve vir das configurações do repositório
    final remoteUrl = Uri.parse(
      'https://repo1.maven.org/maven2/$groupPath/$artifactId/$version/$filename',
    );
    return remoteUrl;
  }
}
