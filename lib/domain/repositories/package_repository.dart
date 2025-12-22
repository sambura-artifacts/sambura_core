import 'package:sambura_core/domain/entities/package_entity.dart';

abstract class PackageRepository {
  /// Busca um pacote pelo nome e pelo ID do repositório
  Future<PackageEntity?> findByName(int repositoryId, String name);

  /// Lista pacotes filtrando pelo NOME do repositório (ex: npm-proxy)
  /// Adicionada paginação para escala.
  Future<List<PackageEntity>> listByRepositoryName(
    String repoName, {
    int limit = 20,
    int offset = 0,
  });

  /// Garante a existência de um pacote (Upsert).
  Future<PackageEntity> ensurePackage({
    required int repositoryId,
    required String name,
  });

  // Mantendo os outros por retrocompatibilidade se precisar
  Future<PackageEntity?> findByGlobalName(String name);
  Future<List<PackageEntity>> listByNamespace(String name);
}
