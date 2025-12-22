import 'package:uuid/uuid.dart';
import 'package:sambura_core/domain/entities/blob_entity.dart';

class ArtifactEntity {
  final int? id; // PK serial do Postgres
  final String externalId; // UUID v7
  final int packageId; // FK para a tabela 'packages' (Essencial!)
  final String namespace; // Escopo/Organização
  final String packageName; // Nome legível
  final String version; // SemVer
  final String path; // Caminho lógico
  final int? blobId; // FK para a tabela 'blobs' (Essencial!)
  final BlobEntity? blob; // Dados do arquivo
  final DateTime createdAt;

  // Construtor privado para controle total das instâncias
  ArtifactEntity._({
    this.id,
    required this.externalId,
    required this.packageId,
    required this.namespace,
    required this.packageName,
    required this.version,
    required this.path,
    this.blobId,
    this.blob,
    required this.createdAt,
  });

  /// Ponto de entrada para criação via UseCase.
  /// Note que agora pedimos o [packageId] que veio da busca prévia no banco.
  static ArtifactEntity create({
    required int packageId,
    required String namespace,
    required String packageName,
    required String version,
    required String path,
    required BlobEntity blob,
  }) {
    return ArtifactEntity._(
      externalId: const Uuid().v7(),
      packageId: packageId,
      namespace: namespace,
      packageName: packageName,
      version: version,
      path: path,
      blobId: blob.id, // Se o blob já foi salvo, o id tá aqui
      blob: blob,
      createdAt: DateTime.now().toUtc(),
    );
  }

  /// Restaura a entidade vinda do repositório (JOIN entre artifacts e blobs)
  factory ArtifactEntity.fromRepository(
    Map<String, dynamic> artifactRow,
    Map<String, dynamic> blobRow,
  ) {
    return ArtifactEntity._(
      id: artifactRow['id'] as int?,
      externalId: artifactRow['external_id'] as String,
      packageId: artifactRow['package_id'] as int,
      namespace:
          artifactRow['namespace'] as String? ?? '', // Fallback se vier de JOIN
      packageName: artifactRow['package_name'] as String? ?? '',
      version: artifactRow['version'] as String,
      path: artifactRow['path'] as String,
      blobId: artifactRow['blob_id'] as int?,
      blob: BlobEntity.restore(
        blobRow['id'] as int,
        blobRow['blob_hash'] as String,
        blobRow['size_bytes'] as int,
        blobRow['mime'] as String? ?? blobRow['mime_type'] as String,
        blobRow['created_at'] as DateTime,
      ),
      createdAt: artifactRow['created_at'] is DateTime
          ? artifactRow['created_at'] as DateTime
          : DateTime.parse(artifactRow['created_at'].toString()),
    );
  }

  /// Cria uma cópia da entidade alterando campos específicos (Imutabilidade)
  ArtifactEntity copyWith({
    int? id,
    int? packageId,
    int? blobId,
    BlobEntity? blob,
  }) {
    return ArtifactEntity._(
      id: id ?? this.id,
      externalId: externalId,
      packageId: packageId ?? this.packageId,
      namespace: namespace,
      packageName: packageName,
      version: version,
      path: path,
      blobId: blobId ?? this.blobId,
      blob: blob ?? this.blob,
      createdAt: createdAt,
    );
  }

  // Getters simplificados (clean code)
  bool get isPersisted => id != null;
}
