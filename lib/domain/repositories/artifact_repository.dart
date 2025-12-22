import 'package:sambura_core/domain/entities/artifact_entity.dart';

abstract class ArtifactRepository {
  /// Persiste um novo artefato no banco de dados.
  /// Retorna a entidade com o ID gerado pelo Postgres.
  Future<ArtifactEntity> save(ArtifactEntity artifact);

  /// Recupera a projeção completa do artefato (Hydrated Entity) via seu UUID público.
  /// Implementações devem priorizar o Cache Aside para reduzir latência de leitura.
  Future<ArtifactEntity?> getByExternalId(String externalId);

  /// Localiza um artefato através da sua rota lógica única dentro de um namespace.
  /// Essencial para resoluções de pacotes via CLI (NPM, Pub, Maven).
  Future<ArtifactEntity?> getByPath(String namespace, String path);

  /// Lista a coleção de artefatos vinculados a um escopo de isolamento (Namespace).
  Future<List<ArtifactEntity>> listByNamespace(String namespace);

  /// Lista as versões de um pacote específico utilizando o identificador interno do catálogo.
  Future<List<ArtifactEntity>> listArtifactsByPackage(int packageId);

  Future<String?> findHashByVersion({
    required String namespace,
    required String name,
    required String version,
  });

  /// Solicita a remoção lógica ou física do ponteiro do artefato.
  /// Nota: Preserva o Blob físico para manter a integridade da Deduplicação Global.
  Future<void> delete(ArtifactEntity artifact);
}
