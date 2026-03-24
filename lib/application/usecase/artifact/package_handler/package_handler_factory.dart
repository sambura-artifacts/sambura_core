import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/docker_handler.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/maven_handler.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/npm_handler.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/nuget_handler.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/package_handler.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/pypi_handler.dart';
import 'package:sambura_core/application/usecase/usecases.dart';
import 'package:sambura_core/domain/entities/entities.dart';

class PackageHandlerFactory {
  final HttpClientPort _httpClient;
  final CreateArtifactUsecase _createArtifact;
  final GetArtifactDownloadStreamUsecase _getArtifactDownloadStreamUsecase;
  final CachePort _cache;
  final MetricsPort _metrics;

  PackageHandlerFactory(
    this._httpClient,
    this._createArtifact,
    this._getArtifactDownloadStreamUsecase,
    this._cache,
    this._metrics,
  );

  PackageHandler create(RepositoryType type) {
    switch (type) {
      case RepositoryType.npm:
        return NpmHandler(
          _httpClient,
          _createArtifact,
          _getArtifactDownloadStreamUsecase,
          _cache,
          _metrics,
        );
      case RepositoryType.maven:
        return MavenHandler(
          _httpClient,
          _createArtifact,
          _getArtifactDownloadStreamUsecase,
          _cache,
          _metrics,
        );
      case RepositoryType.pypi:
        return PypiHandler(
          _httpClient,
          _createArtifact,
          _getArtifactDownloadStreamUsecase,
          _cache,
          _metrics,
        );
      case RepositoryType.nuget:
        return NugetHandler(
          _httpClient,
          _createArtifact,
          _getArtifactDownloadStreamUsecase,
          _cache,
          _metrics,
        );
      case RepositoryType.docker:
        return DockerHandler(
          _httpClient,
          _createArtifact,
          _getArtifactDownloadStreamUsecase,
          _cache,
          _metrics,
        );
      default:
        throw Exception('Unsupported repository type: $type');
    }
  }
}
