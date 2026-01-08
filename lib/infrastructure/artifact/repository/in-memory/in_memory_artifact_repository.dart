import 'package:sambura_core/domain/artifact/artifact.dart';

class InMemoryArtifactRepository implements ArtifactRepository {
  final Map<String, ArtifactEntity> _artifacts = {};
  bool shouldThrowError = false;

  void _checkError() {
    if (shouldThrowError) throw Exception('Database error');
  }

  @override
  Future<ArtifactEntity> save(ArtifactEntity artifact) async {
    _checkError();
    _artifacts[artifact.externalId.value] = artifact;
    return artifact;
  }

  @override
  Future<ArtifactEntity?> findByNameAndVersion(
    String namespace,
    String name,
    String version,
  ) async {
    _checkError();
    try {
      return _artifacts.values.firstWhere(
        (a) =>
            a.namespace == namespace &&
            a.nameValue == name &&
            a.version.value == version,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ArtifactEntity?> getByPath(String namespace, String path) async {
    _checkError();
    try {
      return _artifacts.values.firstWhere(
        (a) => a.namespace == namespace && a.path == path,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ArtifactEntity>> findAllVersions(
    String repoName,
    String packageName,
  ) async {
    _checkError();
    return _artifacts.values
        .where((a) => a.packageName.value == packageName)
        .toList();
  }

  @override
  Future<ArtifactEntity?> findOne(
    String repoName,
    String packageName,
    String version,
  ) async {
    _checkError();
    try {
      return _artifacts.values.firstWhere(
        (a) => a.packageName.value == packageName && a.version.value == version,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ArtifactEntity?> getByExternalId(String externalId) async {
    _checkError();
    return _artifacts[externalId];
  }

  @override
  Future<void> delete(ArtifactEntity artifact) async {
    _checkError();
    _artifacts.remove(artifact.externalId.value);
  }

  @override
  Future<bool> isHealthy() async => !shouldThrowError;

  @override
  Future<List<ArtifactEntity>> listByNamespace(String namespace) async {
    _checkError();
    return _artifacts.values.where((a) => a.namespace == namespace).toList();
  }

  @override
  Future<String?> findHashByVersion(
    String namespace,
    String name,
    String version,
  ) async {
    _checkError();
    final artifact = await findByNameAndVersion(namespace, name, version);
    return artifact!.blob!.hash;
  }

  @override
  Future<ArtifactEntity?> findByFileName(
    String repositoryName,
    String packageName,
    String fileName,
  ) async {
    _checkError();
    try {
      return _artifacts.values.firstWhere(
        (a) => a.packageName.value == packageName,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ArtifactEntity>> listArtifactsByPackage(int packageId) async {
    _checkError();
    return _artifacts.values.where((a) => a.packageId == packageId).toList();
  }

  void clear() => _artifacts.clear();
}
