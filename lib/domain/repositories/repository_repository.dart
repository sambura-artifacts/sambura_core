import 'package:sambura_core/domain/entities/repository_entity.dart';

abstract class RepositoryRepository {
  // Adiciona os parâmetros opcionais pra não quebrar quem já usa
  Future<List<RepositoryEntity>> list({int limit = 10, int offset = 0});

  /// Busca a configuração de um repositório pelo nome único (ex: 'npm-internal').
  Future<RepositoryEntity?> getByName(String name);

  /// Lista todos os repositórios de um determinado namespace (ex: todos do 'npm').
  Future<List<RepositoryEntity>> listByNamespace(String namespace);

  /// Salva ou atualiza um repositório.
  Future<RepositoryEntity> save(RepositoryEntity repository);
}
