import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:sambura_core/domain/entities/artifact_entity.dart';
import 'package:sambura_core/domain/entities/package_entity.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';
import 'package:sambura_core/domain/repositories/package_repository.dart';
import 'package:sambura_core/domain/repositories/repository_repository.dart';
import 'package:sambura_core/domain/repositories/blob_repository.dart';

class UploadArtifactUsecase {
  final ArtifactRepository _artifactRepo;
  final PackageRepository _packageRepo;
  final RepositoryRepository _repoRepo;
  final BlobRepository _blobRepo;

  UploadArtifactUsecase(
    this._artifactRepo,
    this._packageRepo,
    this._repoRepo,
    this._blobRepo,
  );

  Future<void> execute({
    required String repoName,
    required String packageName,
    required String version,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    // 1. Gera o Hash e salva o conteúdo no Silo (Deduplicação inclusa)
    final fileHash = sha256.convert(fileBytes).toString();
    final blobEntity = await _blobRepo.saveContent(fileHash, fileBytes);

    // 2. Garante que o Repositório existe
    final repository = await _repoRepo.getByName(repoName);
    if (repository == null) {
      throw Exception('Repositório $repoName não encontrado no mapa, cria!');
    }

    // 3. Busca ou Cria o Pacote (Auto-provisionamento)
    final packages = await _packageRepo.findByRepositoryNameAndPackageName(
      repoName,
      packageName,
    );

    late final PackageEntity package;

    if (packages.isEmpty) {
      // Se não existe, cria o pacote vinculado ao repositório
      package = await _packageRepo.ensurePackage(
        repositoryId: repository.id!,
        name: packageName,
      );
    } else {
      package = packages.first;
    }

    // 4. Cria a entidade do Artefato com o Path original
    final artifactToSave = ArtifactEntity.create(
      packageId: package.id!,
      version: version,
      packageName: packageName,
      namespace: repoName,
      path: fileName, // Nome original do arquivo (ex: lib.tgz)
      blob: blobEntity,
    );

    // 5. Persiste o artefato final
    await _artifactRepo.save(artifactToSave);
  }
}
