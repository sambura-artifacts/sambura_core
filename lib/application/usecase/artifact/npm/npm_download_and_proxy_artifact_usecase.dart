import 'dart:async';
import 'dart:typed_data';
import 'package:logging/logging.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class NpmDownloadAndProxyArtifactUsecase {
  final GetArtifactDownloadStreamUsecase _getArtifactDownloadStreamUsecase;
  final NamespaceRepository _namespaceRepository;
  final PackageHandlerFactory _packageHandlerFactory;
  final Logger _log = LoggerConfig.getLogger(
    'NpmDownloadAndProxyArtifactUsecase',
  );

  NpmDownloadAndProxyArtifactUsecase(
    this._getArtifactDownloadStreamUsecase,
    this._namespaceRepository,
    this._packageHandlerFactory,
  );

  Future<Stream<Uint8List>?> execute(
    InfraestructureArtifactInput inputDto,
  ) async {
    // 1. Tenta buscar o artefato localmente
    _log.info(
      'Buscando artefato localmente: ${inputDto.namespace}/${inputDto.packageName}@${inputDto.version}',
    );
    final localArtifact = await _getArtifactDownloadStreamUsecase.execute(
      namespace: inputDto.namespace,
      name: inputDto.packageName,
      version: inputDto.version!,
    );

    if (localArtifact != null) {
      _log.info('Artefato encontrado localmente. Iniciando stream...');
      return localArtifact.stream;
    }

    _log.info('Artefato não encontrado localmente, tentando proxy...');
    // 2. Se não encontrar, busca as configurações do repositório
    final repository = await _namespaceRepository.getByName(inputDto.namespace);
    _log.info(
      'Repositório ${inputDto.namespace} encontrado: ${repository != null}',
    );
    if (repository == null) {
      throw Exception('Repositório ${inputDto.remoteUrl} não encontrado');
    }

    final input = ApplicationArtifactInput(
      packageManager: 'npm',
      remoteUrl: repository.remoteUrl,
      namespace: inputDto.namespace,
      packageName: inputDto.packageName,
      version: inputDto.version!,
    ).sanitize();

    // 3. Usa a Factory para obter o handler correto e delega
    final handler = _packageHandlerFactory.create();
    return handler.handle(input);
  }
}
