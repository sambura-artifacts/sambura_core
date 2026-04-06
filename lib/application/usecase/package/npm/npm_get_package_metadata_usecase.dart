import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:logging/logging.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class NpmGetPackageMetadataUseCase {
  final ArtifactRepository _artifactRepository;
  final NamespaceRepository _namespaceRepository;
  final HttpClientPort _httpClient; // Dependência adicionada
  final Logger _log = LoggerConfig.getLogger('NpmGetPackageMetadataUseCase');

  NpmGetPackageMetadataUseCase(
    this._artifactRepository,
    this._namespaceRepository,
    this._httpClient,
  );

  Future<Map<String, dynamic>?> execute(
    InfraestructureArtifactInput inputDto,
  ) async {
    try {
      _log.fine(
        'Consultando versões locais do pacote: ${inputDto.packageName}',
      );

      final artifacts = await _artifactRepository.findAllVersions(
        inputDto.namespace,
        inputDto.packageName,
      );

      final namespace = await _namespaceRepository.getByName(
        inputDto.namespace,
      );

      if (namespace == null) _log.warning('Namespace não encontrado');

      _log.info('Namespace: ${namespace?.toMap()}');

      inputDto.remoteUrl = namespace?.remoteUrl;

      // =======================================================================
      // 1. FALLBACK PROXY: Pacote não existe no banco local
      // =======================================================================
      if (artifacts.isEmpty) {
        _log.info(
          'Pacote não encontrado localmente. Iniciando Proxy Upstream...',
        );
        return await _fetchFromUpstream(inputDto);
      }

      // =======================================================================
      // 2. RETORNO LOCAL (Código Original)
      // =======================================================================
      _log.info('Encontradas ${artifacts.length} versões locais.');
      final versions = <String, dynamic>{};

      for (var a in artifacts) {
        final blob = a.blob;
        if (blob == null) continue;

        final hexHash = blob.hash;
        final bytes = hex.decode(hexHash);
        final base64Hash = base64.encode(bytes);
        final integrity = "sha256-$base64Hash";

        versions[a.versionValue] = {
          "name": inputDto.packageName,
          "version": a.version.value,
          "dist": {
            // Samburá é a fonte
            "tarball":
                "http://localhost:8080/api/v1/download/${inputDto.namespace}/${inputDto.packageName}/${a.version.value}",
            "integrity": integrity,
            "shasum": hexHash,
          },
        };
      }

      if (versions.isEmpty) return null;

      final latestVersion = artifacts.last.version.value;
      return {
        "name": inputDto.packageName,
        "dist-tags": {"latest": latestVersion},
        "versions": versions,
      };
    } catch (e, stack) {
      _log.severe(
        '✗ Erro ao buscar metadata de ${inputDto.packageName}',
        e,
        stack,
      );
      rethrow;
    }
  }

  // =======================================================================
  // 3. LÓGICA DO PROXY E REESCRITA DE URL
  // =======================================================================
  Future<Map<String, dynamic>?> _fetchFromUpstream(
    InfraestructureArtifactInput inputDto,
  ) async {
    // Usa a URL configurada no repositório (ex: https://registry.npmjs.org)
    final remoteUrl = inputDto.remoteUrl;
    if (remoteUrl == null || remoteUrl.isEmpty) {
      _log.warning('Nenhum remoteUrl configurado para fallback.');
      return null;
    }

    // O NPM exige a barra e o nome do pacote (aceita @scopes com encode se necessário)
    final uri = Uri.parse('$remoteUrl/${inputDto.packageName}');
    _log.info('Buscando metadata em: $uri');

    final response = await _httpClient.get(uri);

    if (response.statusCode == 404) {
      _log.warning('Pacote não encontrado no Upstream (404).');
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('Erro no Proxy Upstream: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // O Pulo do Gato: Reescrever os tarballs do NPM para apontarem para o Samburá
    final versions = data['versions'] as Map<String, dynamic>?;
    if (versions != null) {
      versions.forEach((version, versionData) {
        if (versionData['dist'] != null) {
          // Quando o dev der 'npm install', o NPM baterá no Samburá para baixar o .tgz
          versionData['dist']['tarball'] =
              "http://localhost:8080/api/v1/download/${inputDto.namespace}/${inputDto.packageName}/$version";
        }
      });
    }

    _log.info('Proxy Upstream concluído com sucesso e URLs reescritas.');
    return data;
  }
}
