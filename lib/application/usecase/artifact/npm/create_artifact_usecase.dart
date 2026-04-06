import 'package:logging/logging.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class CreateArtifactUsecase {
  final ArtifactRepository _artifactRepository;
  final PackageRepository _packageRepository;
  final BlobRepository _blobRepository;
  final NamespaceRepository _namespaceRepository;
  final Logger _log = LoggerConfig.getLogger('CreateArtifactUsecase');

  CreateArtifactUsecase(
    this._artifactRepository,
    this._packageRepository,
    this._blobRepository,
    this._namespaceRepository,
  );

  Future<ArtifactEntity?> execute(
    InfraestructureArtifactInput inputDto,
    Stream<List<int>> fileStream,
  ) async {
    try {
      _log.info(
        'Iniciando criação de artefato: ${inputDto.packageName}@${inputDto.version} em ${inputDto.namespace}',
      );

      // 1. Validar Repositório
      _log.fine('Buscando repositório: ${inputDto.namespace}');
      final repository = await _namespaceRepository.getByName(
        inputDto.namespace,
      );

      if (repository == null) {
        _log.severe('✗ Repositório não encontrado: ${inputDto.namespace}');
        throw RepositoryNotFoundException(inputDto.namespace);
      }

      final input = ApplicationArtifactInput(
        packageManager: repository.packageManager,
        remoteUrl: repository.remoteUrl,
        namespace: inputDto.namespace,
        packageName: inputDto.packageName,
        version: inputDto.version!,
      );

      // 2. Persistir o Binário (Blob) no MinIO/S3
      _log.fine('Salvando blob a partir do stream de dados');
      final blob = await _blobRepository.saveFromStream(fileStream);
      _log.info('Blob salvo: (${blob.sizeBytes} bytes)');

      // 3. Garantir que o Pacote existe (Busca ou Cria via Upsert)
      _log.fine('Garantindo existência do package: ${input.packageName}');
      final package = await _packageRepository.ensurePackage(
        namespaceId: repository.id!,
        name: input.packageName,
      );
      _log.info('✅ Package pronto: ${package.name} (ID: ${package.id})');

      // 4. Criar e Salvar a versão do Artefato
      _log.fine('Criando entidade Artifact');
      final artifact = ArtifactEntity.create(
        packageId: package.id!,
        packageName: package.name,
        namespace: input.namespace,
        version: input.version,
        path: input.fileName ?? '',
        blob: blob,
      );

      _log.fine('Salvando artefato no banco de dados');
      final result = await _artifactRepository.save(artifact);

      _log.info(
        '✓ Artifact ${input.version} salvo com sucesso! ID: ${result.externalId}',
      );

      return result;
    } catch (e, stack) {
      _log.severe(
        '✗ Erro ao criar artefato ${inputDto.packageName}@${inputDto.version}',
        e,
        stack,
      );
      rethrow;
    }
  }
}
