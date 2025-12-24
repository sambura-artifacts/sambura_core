import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
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
  final Logger _log = LoggerConfig.getLogger('UploadArtifactUsecase');

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
    _log.info(
      'Upload iniciado: repo=$repoName, package=$packageName@$version, size=${fileBytes.length} bytes, file=$fileName',
    );

    try {
      // 1. Gera o Hash e salva o conteúdo no Silo (Deduplicação inclusa)
      _log.fine('Gerando hash SHA-256 do arquivo');
      final fileHash = sha256.convert(fileBytes).toString();
      _log.fine('Hash gerado: ${fileHash.substring(0, 16)}...');

      _log.fine('Salvando conteúdo no blob repository');
      final blobEntity = await _blobRepo.saveContent(fileHash, fileBytes);
      _log.fine(
        'Blob salvo: ${blobEntity.hashValue.substring(0, 16)}... (${blobEntity.sizeBytes} bytes)',
      );

      // 2. Garante que o Repositório existe
      _log.fine('Verificando existência do repositório: $repoName');
      final repository = await _repoRepo.getByName(repoName);
      if (repository == null) {
        _log.severe('✗ Repositório não encontrado: $repoName');
        throw Exception('Repositório $repoName não encontrado no mapa, cria!');
      }
      _log.fine(
        'Repositório encontrado: ${repository.name} (ID: ${repository.id})',
      );

      // 3. Busca ou Cria o Pacote (Auto-provisionamento)
      _log.fine('Buscando pacote: $packageName');
      final packages = await _packageRepo.findByRepositoryNameAndPackageName(
        repoName,
        packageName,
      );

      late final PackageEntity package;

      if (packages.isEmpty) {
        _log.info('Pacote não existe, criando novo: $packageName');
        // Se não existe, cria o pacote vinculado ao repositório
        package = await _packageRepo.ensurePackage(
          repositoryId: repository.id!,
          name: packageName,
        );
        _log.info('Pacote criado: ${package.name} (ID: ${package.id})');
      } else {
        package = packages.first;
        _log.fine(
          'Pacote existente encontrado: ${package.name} (ID: ${package.id})',
        );
      }

      // 4. Cria a entidade do Artefato com o Path original
      _log.fine('Criando entidade de artefato');
      final artifactToSave = ArtifactEntity.create(
        packageId: package.id!,
        version: version,
        packageName: packageName,
        namespace: repoName,
        path: fileName, // Nome original do arquivo (ex: lib.tgz)
        blob: blobEntity,
      );

      // 5. Persiste o artefato final
      _log.fine('Persistindo artefato no repositório');
      await _artifactRepo.save(artifactToSave);

      _log.info(
        '✓ Upload concluído com sucesso: $packageName@$version (${fileBytes.length} bytes)',
      );
    } catch (e, stack) {
      _log.severe('✗ Erro durante upload de $packageName@$version', e, stack);
      rethrow;
    }
  }
}
