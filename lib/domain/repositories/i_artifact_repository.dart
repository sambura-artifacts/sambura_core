import 'package:sambura_core/domain/entities/artifact_entity.dart';
import 'package:sambura_core/domain/value_objects/package_name.dart';
import 'package:sambura_core/domain/value_objects/version.dart';
import 'package:sambura_core/domain/value_objects/hash.dart';

/// Interface para operações de escrita de artefatos.
/// Segrega responsabilidades de leitura e escrita (CQRS lite).
abstract class IArtifactWriteRepository {
  /// Persiste um novo artefato.
  Future<ArtifactEntity> save(ArtifactEntity artifact);

  /// Remove um artefato (soft ou hard delete).
  Future<void> delete(String artifactId);

  /// Atualiza metadados de um artefato.
  Future<ArtifactEntity> update(ArtifactEntity artifact);
}

/// Interface para operações de leitura de artefatos.
abstract class IArtifactReadRepository {
  /// Busca artefato por ID externo (UUID).
  Future<ArtifactEntity?> findById(String artifactId);

  /// Busca artefato por repositório, pacote e versão.
  Future<ArtifactEntity?> findByPackageVersion({
    required String repositoryName,
    required PackageName packageName,
    required Version version,
  });

  /// Lista todos os artefatos de um pacote.
  Future<List<ArtifactEntity>> findAllByPackage({
    required String repositoryName,
    required PackageName packageName,
  });

  /// Lista artefatos por namespace.
  Future<List<ArtifactEntity>> findByNamespace(String namespace);

  /// Verifica se um artefato existe.
  Future<bool> exists({
    required String repositoryName,
    required PackageName packageName,
    required Version version,
  });
}

/// Interface para consultas específicas de artefatos.
abstract class IArtifactQueryRepository {
  /// Busca hash de um artefato específico.
  Future<Hash?> findHashByVersion({
    required String repositoryName,
    required PackageName packageName,
    required Version version,
  });

  /// Lista todas as versões disponíveis de um pacote.
  Future<List<Version>> listVersions({
    required String repositoryName,
    required PackageName packageName,
  });

  /// Conta quantos artefatos existem em um repositório.
  Future<int> countByRepository(String repositoryName);

  /// Busca artefatos por período de criação.
  Future<List<ArtifactEntity>> findByCreatedAt({
    required DateTime from,
    required DateTime to,
    int? limit,
  });
}
