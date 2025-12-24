import 'package:sambura_core/domain/entities/blob_entity.dart';
import 'package:sambura_core/domain/value_objects/external_id.dart';
import 'package:sambura_core/domain/value_objects/package_name.dart';
import 'package:sambura_core/domain/value_objects/sem_ver.dart';

class ArtifactEntity {
  final int? id;
  final ExternalId externalId; // VO: UUID v7
  final int packageId;
  final String namespace; // Opcional: Criar VO se quiser validar scopes @
  final PackageName packageName; // VO: Valida contra caracteres proibidos
  final SemVer version; // VO: Garante que é 1.0.0 e não "v1"
  final String path;
  final int? blobId;
  final BlobEntity? blob;
  final DateTime createdAt;

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

  static ArtifactEntity create({
    required int packageId,
    required String namespace,
    required String packageName,
    required String version,
    required BlobEntity blob,
    required String path,
  }) {
    return ArtifactEntity._(
      externalId: ExternalId.generate(),
      packageId: packageId,
      namespace: namespace,
      packageName: PackageName(packageName),
      version: SemVer(version),
      path: path,
      blobId: blob.id,
      blob: blob,
      createdAt: DateTime.now().toUtc(),
    );
  }

  factory ArtifactEntity.restore({
    required int id,
    required String externalId,
    required int packageId,
    required String namespace,
    required String packageName,
    required String version,
    required String path,
    int? blobId,
    BlobEntity? blob,
    required DateTime createdAt,
  }) {
    return ArtifactEntity._(
      id: id,
      externalId: ExternalId(externalId), // Reconstrói o VO com o ID existente
      packageId: packageId,
      namespace: namespace,
      packageName: PackageName(packageName),
      version: SemVer(version),
      path: path,
      blobId: blobId,
      blob: blob,
      createdAt: createdAt,
    );
  }

  ArtifactEntity copyWith({
    int? id,
    ExternalId? externalId,
    int? packageId,
    String? namespace,
    PackageName? packageName,
    SemVer? version,
    String? path,
    int? blobId,
    BlobEntity? blob,
    DateTime? createdAt,
  }) {
    return ArtifactEntity._(
      id: id ?? this.id,
      externalId: externalId ?? this.externalId,
      packageId: packageId ?? this.packageId,
      namespace: namespace ?? this.namespace,
      packageName: packageName ?? this.packageName,
      version: version ?? this.version,
      path: path ?? this.path,
      blobId: blobId ?? this.blobId,
      blob: blob ?? this.blob,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get versionValue => version.value;
  String get nameValue => packageName.value;
  String get externalIdValue => externalId.value;
  String get packageNameValue => packageName.value;
}
