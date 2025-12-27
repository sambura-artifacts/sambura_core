
import 'package:sambura_core/domain/entities/entities.dart';
class PackageMapper {
  /// Converte uma linha do banco de dados (Map) para a entidade PackageEntity
  static PackageEntity fromMap(Map<String, dynamic> map) {
    return PackageEntity.restore(
      id: map['id'] as int?,
      repositoryId: map['repository_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: (map['created_at'] as DateTime).toUtc(),
    );
  }

  /// Converte a entidade para um Map (útil para INSERT/UPDATE manuais)
  static Map<String, dynamic> toMap(PackageEntity package) {
    return {
      'id': package.id,
      'repository_id': package.repositoryId,
      'name': package.name,
      'description': package.description,
      'created_at': package.createdAt.toIso8601String(),
    };
  }
}
