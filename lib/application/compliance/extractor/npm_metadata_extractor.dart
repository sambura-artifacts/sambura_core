import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:sambura_core/application/compliance/extractor/metadata_extractor.dart';

/// Extrator de metadados para pacotes NPM
/// Implementa a estratégia de extração de package.json de arquivos .tgz/.tar.gz
class NpmMetadataExtractor implements MetadataExtractor {
  @override
  bool canHandle(String filename) {
    return filename.endsWith('.tgz') || filename.endsWith('.tar.gz');
  }

  @override
  Future<String?> extractPackageMetadata(List<int> bytes) async {
    try {
      // Decodifica gzip
      final decodedTar = GZipDecoder().decodeBytes(bytes);

      // Decodifica tar
      final archive = TarDecoder().decodeBytes(decodedTar);

      // Procura pelo package.json
      for (final file in archive) {
        if (file.name == 'package/package.json' ||
            file.name.endsWith('/package.json')) {
          return utf8.decode(file.content);
        }
      }

      return null;
    } catch (e) {
      // Se houver erro na extração, retorna null
      return null;
    }
  }

  @override
  String getPurlNamespace(String name) {
    // Para NPM, o namespace sempre é "npm"
    // Se o pacote tem escopo (@scope/name), mantém como está
    return 'npm';
  }

  /// Extrai nome e versão do package.json
  Map<String, String>? parsePackageJson(String packageJsonContent) {
    try {
      final json = jsonDecode(packageJsonContent) as Map<String, dynamic>;

      final name = json['name'] as String?;
      final version = json['version'] as String?;

      if (name != null && version != null) {
        return {'name': name, 'version': version};
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
