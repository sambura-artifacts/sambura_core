import 'package:sambura_core/domain/barrel.dart';

/// Factory para criar instâncias de PackageEntity
class PackageFactory {
  /// Cria um novo pacote
  static PackageEntity create({
    required String name,
    int? namespaceId,
    String? description,
  }) {
    return PackageEntity.create(
      name: name,
      namespaceId: namespaceId,
      description: description,
    );
  }

  /// Reconstrói um pacote a partir de um mapa
  static PackageEntity fromMap(Map<String, dynamic> map) {
    return PackageEntity.fromMap(map);
  }
}
