import 'package:sambura_core/domain/entities/entities.dart';

/// Factory para criar instâncias de RepositoryEntity
class RepositoryFactory {
  /// Cria um novo repositório
  static RepositoryEntity create({
    required String remoteUrl,
    required String name,
    required String namespace,
    bool isPublic = false,
    bool active = true,
  }) {
    return RepositoryEntity.create(
      remoteUrl: remoteUrl,
      name: name,
      namespace: namespace,
      isPublic: isPublic,
      active: active,
    );
  }

  /// Reconstrói um repositório a partir de um mapa
  static RepositoryEntity fromMap(Map<String, dynamic> map) {
    return RepositoryEntity.fromMap(map);
  }
}
