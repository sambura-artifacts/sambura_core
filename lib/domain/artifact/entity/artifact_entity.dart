import 'package:sambura_core/domain/entities/entities.dart';
import 'package:sambura_core/domain/value_objects/value_objects.dart';

class ArtifactEntity {
  final int? id;
  final ExternalId externalId;
  final int packageId;
  final String namespace;
  final PackageName packageName;
  final SemVer version;
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
    int? id,
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
      externalId: ExternalId(externalId),
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
