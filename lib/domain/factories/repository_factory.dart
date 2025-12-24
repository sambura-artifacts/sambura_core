import 'package:sambura_core/domain/entities/repository_entity.dart';

/// Factory para criar instâncias de RepositoryEntity
class RepositoryFactory {
  /// Cria um novo repositório
  static RepositoryEntity create({
    required String name,
    required String namespace,
    bool isPublic = false,
  }) {
    return RepositoryEntity.create(
      name: name,
      namespace: namespace,
      isPublic: isPublic,
    );
  }

  /// Reconstrói um repositório a partir de um mapa
  static RepositoryEntity fromMap(Map<String, dynamic> map) {
    return RepositoryEntity.fromMap(map);
  }
}
