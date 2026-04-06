import 'package:sambura_core/domain/barrel.dart';

abstract class NamespaceRepository {
  // Adiciona os parâmetros opcionais pra não quebrar quem já usa
  Future<List<NamespaceEntity>> list({int limit = 10, int offset = 0});

  /// Busca a configuração de um repositório pelo nome único (ex: 'npm-internal').
  Future<NamespaceEntity?> getByName(String name);

  /// Lista todos os repositórios de um determinado namespace (ex: todos do 'npm').
  Future<List<NamespaceEntity>> listByNamespace(String namespace);

  /// Salva ou atualiza um repositório.
  Future<NamespaceEntity> save(NamespaceEntity repository);
}
