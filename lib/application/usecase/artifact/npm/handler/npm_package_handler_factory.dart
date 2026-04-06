import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/domain/barrel.dart';

class PackageHandlerFactory {
  final HttpClientPort _httpClient;
  final CreateArtifactUsecase _createArtifact;
  final GetArtifactDownloadStreamUsecase _getArtifactDownloadStreamUsecase;
  final NamespaceRepository _namespaceRepository;
  final CachePort _cache;
  final MetricsPort _metrics;

  PackageHandlerFactory(
    this._httpClient,
    this._createArtifact,
    this._getArtifactDownloadStreamUsecase,
    this._namespaceRepository,
    this._cache,
    this._metrics,
  );

  NpmPackageHandler create() {
    return NpmHandler(
      _httpClient,
      _createArtifact,
      _getArtifactDownloadStreamUsecase,
      _namespaceRepository,
      _cache,
      _metrics,
    );
  }
}
