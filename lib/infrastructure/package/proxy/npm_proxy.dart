import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/artifact/ports/ports.dart';
import 'package:sambura_core/domain/entities/entities.dart';
import 'package:sambura_core/domain/exceptions/exceptions.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';

class NpmProxy implements RegistryProxyPort {
  final BlobRepository _blobRepository;
  final PackageRepository _packageRepository;
  final String _registryUrl = "https://registry.npmjs.org";
  final Logger _log = LoggerConfig.getLogger('NpmProxyService');

  NpmProxy(this._blobRepository, this._packageRepository);

  @override
  Future<Map<String, dynamic>?> fetchPackageMetadata(String packageName) async {
    final url = Uri.parse("$_registryUrl/$packageName");
    _log.info('🌐 Upstream Metadata: $url');

    try {
      final response = await http.get(url);
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw Exception("Erro Upstream NPM: ${response.statusCode}");
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      _log.severe('❌ Erro ao buscar metadados de $packageName', e);
      return null;
    }
  }

  @override
  Future<Stream<List<int>>?> fetchArtifact(
    String packageName,
    String fileName,
  ) async {
    final url = Uri.parse("$_registryUrl/$packageName/-/$fileName");
    _log.info('🌐 Upstream Tarball: $url');

    try {
      final client = http.Client();
      final request = http.Request('GET', url);
      final response = await client.send(request);

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) return null;

      return response.stream;
    } catch (e) {
      _log.severe('❌ Erro ao buscar tarball $fileName', e);
      return null;
    }
  }

  @override
  Future<ArtifactEntity> fetchTarball({
    required String packageName,
    required String fileName,
    required String repositoryName,
  }) async {
    _log.info('🌐 Proxy Fetch: $packageName/$fileName');

    final stream = await fetchArtifact(packageName, fileName);
    if (stream == null) {
      throw ArtifactNotFoundException('Upstream não encontrou: $fileName');
    }

    final blob = await _blobRepository.saveFromStream(stream);

    final package = await _packageRepository.getOrCreate(
      repositoryName: repositoryName,
      packageName: packageName,
    );

    return ArtifactEntity.create(
      packageId: package.id!,
      namespace: repositoryName,
      packageName: packageName,
      version: _extractVersion(fileName),
      blob: blob,
      path: fileName,
    );
  }

  String _extractVersion(String fileName) {
    final match = RegExp(r'-(\d+\.\d+\.\d+.*)\.tgz$').firstMatch(fileName);
    return match?.group(1) ?? '0.0.0-proxy';
  }

  @override
  Future<ArtifactEntity> fetchAndStore(
    String packageName,
    String version,
  ) async {
    final metadata = await fetchPackageMetadata(packageName);

    if (metadata == null || !metadata.containsKey('versions')) {
      throw ArtifactNotFoundException(packageName);
    }

    final versionData = metadata['versions'][version];
    if (versionData == null) {
      throw ArtifactNotFoundException('$packageName@$version');
    }

    final String tarballUrl = versionData['dist']['tarball'];
    final fileName = tarballUrl.split('/').last;

    return await fetchTarball(
      packageName: packageName,
      fileName: fileName,
      repositoryName: 'npm-proxy',
    );
  }

  @override
  Future<bool> packageExists(String packageName) async {
    final url = Uri.parse("$_registryUrl/$packageName");

    try {
      final response = await http.head(url);
      return response.statusCode == 200 ? true : false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> listVersions(String packageName) async {
    final metadata = await fetchPackageMetadata(packageName);
    if (metadata == null || !metadata.containsKey('versions')) return [];
    final versionsMap = metadata['versions'] as Map<String, dynamic>;
    return versionsMap.keys.toList();
  }
}
