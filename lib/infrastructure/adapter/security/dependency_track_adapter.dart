import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/application/barrel.dart';

class DependencyTrackAdapter implements CompositionAnalysisPort {
  final HttpClientPort _httpClient;
  final String _baseUrl;
  final String _apiKey;
  final Logger _log = LoggerConfig.getLogger('DependencyTrackAdapter');

  DependencyTrackAdapter(this._httpClient, this._baseUrl, this._apiKey);

  @override
  Future<void> analyze({
    required String packageName,
    required String version,
    required String projectType,
    required List<int> fileBytes,
    String? fileName, // Adicione este parâmetro na interface
  }) async {
    try {
      _log.info(
        'Criando ou garantindo existência do projeto no D-Track para $packageName@$version...',
      );
      final String projectUUID = await ensureProjectExists(
        projectType,
        packageName,
        version,
      );

      _log.info(
        '🔒 Verificando análise de segurança para $packageName@$version...',
      );

      String base64Bom = _generateOrExtractSbom(
        fileBytes,
        packageName,
        version,
        projectType,
      );

      _log.info('Enviando SBOM para o Dependency-Track...');
      await _sendToDTrack(projectUUID, base64Bom);
    } catch (e) {
      _log.severe('Erro na integração com o Dependency-Track', e);
    }
  }

  Future<void> _sendToDTrack(String projectUUID, String base64Bom) async {
    _log.info(
      'Enviando SBOM para o Dependency-Track (projectUUID=$projectUUID)...',
    );
    _log.fine(
      'SBOM base64 (primeiros 100 chars): ${base64Bom.substring(0, 100)}',
    );
    final body = jsonEncode({'project': projectUUID, 'bom': base64Bom});
    _log.fine('Payload JSON para D-Track: $body');
    final response = await _httpClient.put(
      Uri.parse('$_baseUrl/api/v1/bom'),
      headers: {'X-Api-Key': _apiKey, 'Content-Type': 'application/json'},
      body: body,
    );
    _log.info(response);
    if (response.statusCode == 201 || response.statusCode == 200) {
      _log.info('✅ SBOM processado pelo Dependency-Track.');
    }
  }

  @override
  Future<bool> isSecure(String packageName, String version) async {
    // Busca o projeto por nome e versão
    final lookupResponse = await _httpClient.get(
      Uri.parse(
        '$_baseUrl/api/v1/project/lookup?name=$packageName&version=$version',
      ),
      headers: {'X-Api-Key': _apiKey},
    );

    if (lookupResponse.statusCode != 200) {
      _log.warning(
        'Falha ao buscar projeto no Dependency-Track: ${lookupResponse.body}',
      );
      return true; // Se não conhece, permite (fail-open)
    }

    final project = jsonDecode(lookupResponse.body);
    final projectUUID = project['uuid'];

    // 2. Bate no endpoint de MÉTRICAS reais
    final metricsResponse = await _httpClient.get(
      Uri.parse('$_baseUrl/api/v1/metrics/project/$projectUUID/current'),
      headers: {'X-Api-Key': _apiKey},
    );

    if (metricsResponse.statusCode == 200 && metricsResponse.body.isNotEmpty) {
      final metrics = jsonDecode(metricsResponse.body);

      final int critical = metrics['critical'] ?? 0;
      final int high = metrics['high'] ?? 0;

      if (critical > 0 || high > 0) {
        _log.warning(
          '❌ Bloqueado! $packageName@$version possui $critical falhas críticas.',
        );
        return false;
      }
    }

    return true;
  }

  @override
  Future<String> ensureProjectExists(
    String projectType,
    String name,
    String version,
  ) async {
    // 1. Tenta buscar o projeto primeiro (Lookup)
    final lookupResponse = await _httpClient.get(
      Uri.parse('$_baseUrl/api/v1/project/lookup?name=$name&version=$version'),
      headers: {'X-Api-Key': _apiKey},
    );

    if (lookupResponse.statusCode == 200) {
      final project = jsonDecode(lookupResponse.body);
      return project['uuid'];
    }

    // 2. Se não existir, cria o projeto
    _log.info('Criando novo projeto no D-Track: $name@$version');
    final createResponse = await _httpClient.put(
      // D-Track usa PUT para criação simples
      Uri.parse('$_baseUrl/api/v1/project'),
      headers: {'X-Api-Key': _apiKey, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'version': version,
        'classifier': 'LIBRARY',
        'tags': [
          {'name': projectType},
        ],
        'active': true,
      }),
    );

    if (createResponse.statusCode == 201) {
      final newProject = jsonDecode(createResponse.body);
      return newProject['uuid'];
    }

    throw Exception(
      'Falha ao garantir existência do projeto: ${createResponse.body}',
    );
  }

  @override
  Future<bool> existsAnalysis(String packageName, String version) async {
    final response = await _httpClient.get(
      Uri.parse(
        '$_baseUrl/api/v1/project/lookup?name=$packageName&version=$version',
      ),
      headers: {'X-Api-Key': _apiKey},
    );

    return response.statusCode == 200;
  }

  String _generateOrExtractSbom(
    List<int> fileBytes,
    String name,
    String version,
    String projectType,
  ) {
    try {
      // 1. Descompactar o .tgz (GZip -> Tar)
      final tarBytes = GZipDecoder().decodeBytes(fileBytes);
      final archive = TarDecoder().decodeBytes(tarBytes);

      // 2. Procurar o package.json (no NPM fica sempre em 'package/package.json')
      final packageFile = archive.files.firstWhere(
        (f) => f.name.endsWith('package.json'),
        orElse: () => throw Exception('package.json não encontrado no tarball'),
      );

      final Map<String, dynamic> packageJson = jsonDecode(
        utf8.decode(packageFile.content),
      );
      final dependencies =
          packageJson['dependencies'] as Map<String, dynamic>? ?? {};

      final mainPurl = "pkg:npm/${name.replaceAll('@', '%40')}@$version";

      // 3. Montar o JSON no formato CycloneDX 1.4
      final sbom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.4",
        "serialNumber":
            "urn:uuid:${const Uuid().v4()}", // Podes usar um random ou hash
        "version": 1,
        "metadata": {
          "timestamp": DateTime.now().toUtc().toIso8601String(),
          "component": {
            "bom-ref": mainPurl,
            "name": name,
            "version": version,
            "type": "library",
            "purl": mainPurl,
          },
        },
        "components": dependencies.entries.map((e) {
          final cleanVersion = e.value
              .toString()
              .replaceAll('^', '')
              .replaceAll('~', '')
              .split(' ')[0];

          final escapedName = e.key.replaceAll('@', '%40');

          return {
            "type": "library",
            "name": e.key,
            "version": cleanVersion,
            "purl":
                "pkg:$projectType/$escapedName@$cleanVersion", // Use a limpa aqui!
            "bom-ref": "pkg:$projectType/$escapedName@$cleanVersion", // E aqui!
          };
        }).toList(),
        "dependencies": [
          {
            "ref": mainPurl,
            "dependsOn": dependencies.keys.map((k) {
              final cleanV = dependencies[k]
                  .toString()
                  .replaceAll('^', '')
                  .replaceAll('~', '')
                  .split(' ')[0];
              final escapedName = k.replaceAll('@', '%40');

              return "pkg:$projectType/$escapedName@$cleanV";
            }).toList(),
          },
        ],
      };

      return base64Encode(utf8.encode(jsonEncode(sbom)));
    } catch (e) {
      _log.severe('Falha ao gerar SBOM a partir do tarball: $e');
      rethrow;
    }
  }
}
