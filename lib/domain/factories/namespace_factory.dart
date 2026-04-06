import 'package:sambura_core/domain/barrel.dart';

/// Factory para criar instâncias de RepositoryEntity
class NamespaceFactory {
  /// Cria um novo repositório
  static NamespaceEntity create({
    required String packageManager,
    required String remoteUrl,
    required String name,
    required String escope,
    bool isPublic = false,
    bool active = true,
  }) {
    return NamespaceEntity.create(
      packageManager: packageManager,
      remoteUrl: remoteUrl,
      name: name,
      escope: escope,
      isPublic: isPublic,
      active: active,
    );
  }

  /// Reconstrói um repositório a partir de um mapa
  static NamespaceEntity fromMap(Map<String, dynamic> map) {
    return NamespaceEntity.fromMap(map);
  }
}
