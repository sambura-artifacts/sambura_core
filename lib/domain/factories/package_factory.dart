import 'package:sambura_core/domain/entities/package_entity.dart';

/// Factory para criar instâncias de PackageEntity
class PackageFactory {
  /// Cria um novo pacote
  static PackageEntity create({
    required String name,
    int? repositoryId,
    String? description,
  }) {
    return PackageEntity.create(
      name: name,
      repositoryId: repositoryId,
      description: description,
    );
  }

  /// Reconstrói um pacote a partir de um mapa
  static PackageEntity fromMap(Map<String, dynamic> map) {
    return PackageEntity.fromMap(map);
  }
}
